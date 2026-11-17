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
    expect(find.text('Personal goals'), findsOneWidget);
    expect(find.text('Your data'), findsOneWidget);
  });
  test('habit completion history and backup restore work', () async {
    const habitName = 'CI habit history check';
    await Store.addHabit(habitName);
    final habit = (await Store.habits()).firstWhere((row) => row['name'] == habitName);
    final id = habit['id'] as int;
    await Store.toggle(id);

    final stats = await Store.progressStats();
    final counts = stats['habits'] as List<int>;
    expect(counts.last, greaterThanOrEqualTo(1));

    final backup = await Store.createBackup();
    await Store.delete(id);
    expect((await Store.habits()).any((row) => row['name'] == habitName), isFalse);
    await Store.restoreBackup(backup);
    expect((await Store.habits()).any((row) => row['name'] == habitName), isTrue);
    expect(await Store.habitStreak(id), 1);
  });
}
