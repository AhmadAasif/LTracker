import 'package:flutter_test/flutter_test.dart';
import 'package:elora/main.dart';
void main(){testWidgets('ELORA brand renders',(tester)async{await tester.pumpWidget(const EloraApp());expect(find.text('ELORA'),findsWidgets);expect(find.text('Your day, your pace.'),findsOneWidget);});}
