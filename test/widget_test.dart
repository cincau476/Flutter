
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/main.dart';

void main() {
  testWidgets('Gardu SCADA app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GarduScadaApp());

    expect(find.text('Gardu SCADA'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
