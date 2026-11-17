import 'package:elora/main.dart';
import 'package:elora/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('ELORA dashboard renders', (tester) async {
    await tester.pumpWidget(const EloraApp());
    // The dashboard contains an indeterminate loading indicator while SQLite
    // opens. pumpAndSettle would wait forever for that intentional animation.
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('ELORA'), findsWidgets);
    expect(find.text('Your day, your pace.'), findsOneWidget);
    expect(find.text('Today at a glance'), findsOneWidget);
  });

  testWidgets('Profile and goal controls are reachable', (tester) async {
    await tester.pumpWidget(const EloraApp());
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('You'));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Your space'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Personal goals'), 350, scrollable: find.byType(Scrollable).last);
    expect(find.text('Personal goals'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Your data'), 350, scrollable: find.byType(Scrollable).last);
    expect(find.text('Your data'), findsOneWidget);
  });
  test('habit completion history and backup restore work', () async {
    const habitName = 'CI habit history check';
    print('STORE_TEST: add habit');
    await Store.addHabit(habitName);
    final habit = (await Store.habits()).firstWhere((row) => row['name'] == habitName);
    final id = habit['id'] as int;
    print('STORE_TEST: toggle habit');
    await Store.toggle(id);

    print('STORE_TEST: progress stats');
    final stats = await Store.progressStats();
    final counts = stats['habits'] as List<int>;
    expect(counts.last, greaterThanOrEqualTo(1));

    print('STORE_TEST: add wellbeing logs');
    await Store.addWater(250);
    await Store.logWeight(70.2);
    // Exercise the current schema, including optional wellbeing logs.
    print('STORE_TEST: create backup');
    final backup = await Store.createBackup();
    print('STORE_TEST: delete habit');
    await Store.delete(id);
    expect((await Store.habits()).any((row) => row['name'] == habitName), isFalse);
    print('STORE_TEST: restore backup');
    await Store.restoreBackup(backup);
    print('STORE_TEST: restored');
    expect((await Store.habits()).any((row) => row['name'] == habitName), isTrue);
    expect(await Store.habitStreak(id), 1);
    expect(await Store.waterToday(), 250);
    expect((await Store.weightHistory()).first['weight_kg'], 70.2);
  });
}
