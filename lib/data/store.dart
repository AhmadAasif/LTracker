import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class Store {
  static Database? _database;

  static Future<Database> get db async {
    if (_database != null) return _database!;
    final dir = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dir, 'elora.db'),
      version: 4,
      onCreate: (database, version) async {
        await _createCoreTables(database);
        await _createGoalsTable(database);
        await _createHabitLogsTable(database);
        await _createWellbeingTables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createGoalsTable(database);
        if (oldVersion < 3) {
          await _createHabitLogsTable(database);
          await database.execute('INSERT OR IGNORE INTO habit_logs(habit_id,day) SELECT id,day FROM habits WHERE done=1');
        }
        if (oldVersion < 4) await _createWellbeingTables(database);
      },
    );
    return _database!;
  }

  static Future<void> _createCoreTables(DatabaseExecutor d) async {
    await d.execute('CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,done INTEGER NOT NULL DEFAULT 0,day TEXT NOT NULL)');
    await d.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,amount REAL NOT NULL,category TEXT NOT NULL,day TEXT NOT NULL)');
    await d.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
    await d.execute('CREATE TABLE workouts(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,day TEXT NOT NULL)');
    await d.execute('CREATE TABLE meals(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,day TEXT NOT NULL)');
  }

  static Future<void> _createGoalsTable(DatabaseExecutor d) async {
    await d.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,target TEXT NOT NULL,progress INTEGER NOT NULL DEFAULT 0,created TEXT NOT NULL)');
  }

  static Future<void> _createHabitLogsTable(DatabaseExecutor d) async {
    await d.execute('CREATE TABLE habit_logs(id INTEGER PRIMARY KEY AUTOINCREMENT,habit_id INTEGER NOT NULL,day TEXT NOT NULL,UNIQUE(habit_id,day))');
  }

  static Future<void> _createWellbeingTables(DatabaseExecutor d) async {
    await d.execute('CREATE TABLE water_logs(id INTEGER PRIMARY KEY AUTOINCREMENT,amount_ml INTEGER NOT NULL,day TEXT NOT NULL,created TEXT NOT NULL)');
    await d.execute('CREATE TABLE weight_logs(id INTEGER PRIMARY KEY AUTOINCREMENT,weight_kg REAL NOT NULL,day TEXT NOT NULL,created TEXT NOT NULL)');
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String get day => dateKey(DateTime.now());
  static String month(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static Future<List<Map<String, Object?>>> habits() async =>
      (await (await db).query('habits', orderBy: 'id DESC'));

  static Future<void> addHabit(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    await (await db).insert('habits', {'name': value, 'done': 0, 'day': day});
  }

  static Future<void> toggle(int id) async {
    final database = await db;
    final rows = await database.query('habits', where: 'id=?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return;
    final habit = rows.first;
    final currentlyDone = habit['done'] == 1 && habit['day'] == day;
    if (currentlyDone) {
      await database.delete('habit_logs', where: 'habit_id=? AND day=?', whereArgs: [id, day]);
      await database.update('habits', {'done': 0, 'day': day}, where: 'id=?', whereArgs: [id]);
    } else {
      await database.insert('habit_logs', {'habit_id': id, 'day': day}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await database.update('habits', {'done': 1, 'day': day}, where: 'id=?', whereArgs: [id]);
    }
  }

  static Future<void> delete(int id) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('habit_logs', where: 'habit_id=?', whereArgs: [id]);
      await txn.delete('habits', where: 'id=?', whereArgs: [id]);
    });
  }

  static Future<void> addWater(int amountMl) async {
    if (amountMl < 50 || amountMl > 2000) throw ArgumentError('Choose a sensible water amount.');
    await (await db).insert('water_logs', {'amount_ml': amountMl, 'day': day, 'created': DateTime.now().toIso8601String()});
  }

  static Future<int> waterToday() async {
    final rows = await (await db).rawQuery('SELECT COALESCE(SUM(amount_ml),0) AS total FROM water_logs WHERE day=?', [day]);
    return (rows.first['total'] as num).toInt();
  }

  static Future<void> logWeight(double kg) async {
    if (!kg.isFinite || kg < 20 || kg > 500) throw ArgumentError('Enter a valid weight in kilograms.');
    await (await db).insert('weight_logs', {'weight_kg': kg, 'day': day, 'created': DateTime.now().toIso8601String()});
  }

  static Future<List<Map<String, Object?>>> weightHistory() async =>
      (await (await db).query('weight_logs', orderBy: 'id DESC', limit: 30));

  static Future<void> log(String table, String name) async {
    if (!['meals', 'workouts'].contains(table)) throw ArgumentError('Unsupported log');
    await (await db).insert(table, {'name': name, 'day': day});
  }

  static Future<List<Map<String, Object?>>> list(String table) async {
    if (!['meals', 'workouts'].contains(table)) throw ArgumentError('Unsupported table');
    return (await (await db).query(table, orderBy: 'id DESC'));
  }

  static Future<void> expense(String name, double amount, String category) async {
    if (amount <= 0 || !amount.isFinite) throw ArgumentError('Amount must be positive');
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Description is required');
    await (await db).insert('expenses', {
      'name': value,
      'amount': amount,
      'category': category.trim().isEmpty ? 'Other' : category.trim(),
      'day': day,
    });
  }

  static Future<void> deleteExpense(int id) async {
    await (await db).delete('expenses', where: 'id=?', whereArgs: [id]);
  }

  static Future<void> budget(double amount) async {
    if (amount < 0 || !amount.isFinite) throw ArgumentError('Invalid budget');
    await setSetting('budget', amount.toString());
  }

  static Future<double> getBudget() async => double.tryParse(await getSetting('budget', fallback: '0')) ?? 0;

  static Future<void> setSetting(String key, String value) async {
    await (await db).insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String> getSetting(String key, {String fallback = ''}) async {
    final rows = await (await db).query('settings', where: 'key=?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? fallback : rows.first['value'] as String;
  }

  static Future<String> profileName() => getSetting('profile_name');
  static Future<void> saveProfileName(String name) => setSetting('profile_name', name.trim());

  static Future<List<Map<String, Object?>>> goals() async =>
      (await (await db).query('goals', orderBy: 'id DESC'));

  static Future<void> addGoal(String title, String target) async {
    final name = title.trim();
    if (name.isEmpty) return;
    await (await db).insert('goals', {'title': name, 'target': target.trim(), 'progress': 0, 'created': day});
  }

  static Future<void> updateGoalProgress(int id, int progress) async {
    await (await db).update('goals', {'progress': progress.clamp(0, 100)}, where: 'id=?', whereArgs: [id]);
  }

  static Future<void> deleteGoal(int id) async {
    await (await db).delete('goals', where: 'id=?', whereArgs: [id]);
  }

  static Future<int> habitStreak(int habitId) async {
    final database = await db;
    final rows = await database.query('habit_logs', columns: ['day'], where: 'habit_id=?', whereArgs: [habitId], orderBy: 'day DESC');
    final dates = rows.map((r) => r['day'] as String).toSet();
    var cursor = DateTime.now();
    if (!dates.contains(dateKey(cursor))) cursor = cursor.subtract(const Duration(days: 1));
    var streak = 0;
    while (dates.contains(dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static Future<Map<String, Object>> progressStats({int days = 7}) async {
    final database = await db;
    final labels = <String>[];
    final habitCounts = <int>[];
    final expenseTotals = <double>[];
    final workoutCounts = <int>[];
    final todayDate = DateTime.now();
    for (var i = days - 1; i >= 0; i--) {
      final date = DateTime(todayDate.year, todayDate.month, todayDate.day).subtract(Duration(days: i));
      final key = dateKey(date);
      labels.add('${date.day}/${date.month}');
      habitCounts.add(Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM habit_logs WHERE day=?', [key])) ?? 0);
      final expenses = await database.rawQuery('SELECT COALESCE(SUM(amount),0) AS total FROM expenses WHERE day=?', [key]);
      expenseTotals.add((expenses.first['total'] as num).toDouble());
      workoutCounts.add(Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM workouts WHERE day=?', [key])) ?? 0);
    }
    final goalRows = await goals();
    final goalAverage = goalRows.isEmpty ? 0.0 : goalRows.fold<int>(0, (sum, g) => sum + (g['progress'] as int)) / goalRows.length;
    return {'labels': labels, 'habits': habitCounts, 'expenses': expenseTotals, 'workouts': workoutCounts, 'goalAverage': goalAverage};
  }

  static Future<Map<String, Object>> finance() async {
    final all = await (await db).query('expenses', orderBy: 'id DESC');
    final items = all.where((e) => (e['day'] as String).startsWith(month(DateTime.now()))).toList();
    final spent = items.fold<double>(0, (sum, e) => sum + (e['amount'] as num).toDouble());
    return {'items': items, 'spent': spent, 'budget': await getBudget()};
  }

  static Future<Map<String, Object>> summary() async {
    final allHabits = await habits();
    final financeData = await finance();
    final done = allHabits.where((e) => e['done'] == 1 && e['day'] == day).length;
    return {'done': done, 'totalHabits': allHabits.length, 'spent': financeData['spent'] as double, 'budget': financeData['budget'] as double};
  }

  static const _backupTables = ['habits', 'habit_logs', 'expenses', 'settings', 'workouts', 'meals', 'goals', 'water_logs', 'weight_logs'];

  static Future<String> createBackup() async {
    final database = await db;
    final data = <String, Object?>{};
    for (final table in _backupTables) {
      data[table] = await database.query(table);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'elora-backup',
      'version': 3,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    });
  }

  static Future<void> restoreBackup(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['format'] != 'elora-backup' || ![1, 2, 3].contains(decoded['version'])) {
      throw const FormatException('This is not a supported ELORA backup.');
    }
    final data = decoded['data'];
    if (data is! Map) throw const FormatException('Backup data is missing.');
    for (final table in ['habits', 'expenses', 'settings', 'workouts', 'meals', 'goals']) {
      if (data[table] is! List) throw FormatException('Backup is missing $table data.');
    }
    if (decoded['version'] >= 2 && data['habit_logs'] is! List) {
      throw const FormatException('Backup habit history is missing.');
    }
    if (decoded['version'] >= 3 && (data['water_logs'] is! List || data['weight_logs'] is! List)) {
      throw const FormatException('Backup wellbeing history is missing.');
    }
    for (final value in data.values) {
      if (value is List && value.any((row) => row is! Map)) throw const FormatException('Backup contains an invalid data row.');
    }

    final database = await db;
    await database.transaction((txn) async {
      for (final table in _backupTables.reversed) {
        await txn.delete(table);
      }
      for (final table in _backupTables) {
        final rows = data[table];
        if (rows is List) {
          for (final rawRow in rows) {
            final row = Map<String, Object?>.from(rawRow as Map);
            await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
      if (decoded['version'] == 1) {
        await txn.execute('INSERT OR IGNORE INTO habit_logs(habit_id,day) SELECT id,day FROM habits WHERE done=1');
      }
    });
  }
}
