import 'package:flutter_test/flutter_test.dart';
import 'package:hoodly/main.dart';

void main() {
  testWidgets('HoodlyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HoodlyApp());
    expect(find.byType(HoodlyApp), findsOneWidget);
  });
}
