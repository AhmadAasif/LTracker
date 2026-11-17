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
      version: 2,
      onCreate: (database, version) async {
        await _createCoreTables(database);
        await _createGoalsTable(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createGoalsTable(database);
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

  static String get day {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

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
    final value = habit['done'] == 1 && habit['day'] == day ? 0 : 1;
    await database.update('habits', {'done': value, 'day': day}, where: 'id=?', whereArgs: [id]);
  }

  static Future<void> delete(int id) async {
    await (await db).delete('habits', where: 'id=?', whereArgs: [id]);
  }

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
    await (await db).insert(
      'settings',
      {'key': 'budget', 'value': amount.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<double> getBudget() async {
    final rows = await (await db).query('settings', where: 'key=?', whereArgs: ['budget'], limit: 1);
    return rows.isEmpty ? 0 : double.tryParse(rows.first['value'] as String) ?? 0;
  }

  static Future<String> profileName() async {
    final rows = await (await db).query('settings', where: 'key=?', whereArgs: ['profile_name'], limit: 1);
    return rows.isEmpty ? '' : rows.first['value'] as String;
  }

  static Future<void> saveProfileName(String name) async {
    final value = name.trim();
    await (await db).insert(
      'settings',
      {'key': 'profile_name', 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, Object?>>> goals() async =>
      (await (await db).query('goals', orderBy: 'id DESC'));

  static Future<void> addGoal(String title, String target) async {
    final name = title.trim();
    if (name.isEmpty) return;
    await (await db).insert('goals', {
      'title': name,
      'target': target.trim(),
      'progress': 0,
      'created': day,
    });
  }

  static Future<void> updateGoalProgress(int id, int progress) async {
    await (await db).update(
      'goals',
      {'progress': progress.clamp(0, 100)},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteGoal(int id) async {
    await (await db).delete('goals', where: 'id=?', whereArgs: [id]);
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
    return {
      'done': done,
      'spent': financeData['spent'] as double,
      'budget': financeData['budget'] as double,
    };
  }

  static const _backupTables = ['habits', 'expenses', 'settings', 'workouts', 'meals', 'goals'];

  static Future<String> createBackup() async {
    final database = await db;
    final data = <String, Object?>{};
    for (final table in _backupTables) {
      data[table] = await database.query(table);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'elora-backup',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    });
  }

  static Future<void> restoreBackup(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['format'] != 'elora-backup' || decoded['version'] != 1) {
      throw const FormatException('This is not a supported ELORA backup.');
    }
    final data = decoded['data'];
    if (data is! Map) throw const FormatException('Backup data is missing.');
    for (final table in _backupTables) {
      if (data[table] is! List) throw FormatException('Backup is missing $table data.');
      for (final row in data[table] as List) {
        if (row is! Map) throw FormatException('Invalid row in $table.');
      }
    }

    final database = await db;
    await database.transaction((txn) async {
      for (final table in _backupTables) {
        await txn.delete(table);
        for (final rawRow in data[table] as List) {
          final row = Map<String, Object?>.from(rawRow as Map);
          await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
