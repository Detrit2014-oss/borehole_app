import 'package:flutter_test/flutter_test.dart';
import 'package:borehole_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BoreholeApp());
    expect(find.text('Буровые скважины'), findsOneWidget);
  });
}
