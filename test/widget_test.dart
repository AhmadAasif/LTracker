import 'package:elora/main.dart';
import 'package:flutter/material.dart' show Scrollable;
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
}
