import 'package:elora/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('ELORA dashboard renders', (tester) async {
    await tester.pumpWidget(const EloraApp());
    await tester.pumpAndSettle();

    expect(find.text('ELORA'), findsWidgets);
    expect(find.text('Your day, your pace.'), findsOneWidget);
    expect(find.text('Today at a glance'), findsOneWidget);
  });
}
