import 'package:elora/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await Store.useDatabasePathForTesting(inMemoryDatabasePath);
  });

  tearDownAll(() async {
    await Store.close();
  });

  test('habit history, wellbeing logs and backup restore work', () async {
    const habitName = 'CI habit history check';
    await Store.addHabit(habitName);
    final habit = (await Store.habits()).firstWhere((row) => row['name'] == habitName);
    final id = habit['id'] as int;
    await Store.toggle(id);

    final stats = await Store.progressStats();
    final counts = stats['habits'] as List<int>;
    expect(counts.last, greaterThanOrEqualTo(1));

    await Store.addWater(250);
    await Store.logWeight(70.2);
    final backup = await Store.createBackup();

    await Store.delete(id);
    expect((await Store.habits()).any((row) => row['name'] == habitName), isFalse);
    await Store.restoreBackup(backup);

    expect((await Store.habits()).any((row) => row['name'] == habitName), isTrue);
    expect(await Store.habitStreak(id), 1);
    expect(await Store.waterToday(), 250);
    expect((await Store.weightHistory()).first['weight_kg'], 70.2);
  });
}
