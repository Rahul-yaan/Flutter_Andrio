import 'package:flutter_test/flutter_test.dart';
import 'package:yaan/main.dart';
import 'package:yaan/pages/logo_page.dart';

void main() {
  testWidgets('Yaan User App launches and displays LogoPage', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(LogoPage), findsOneWidget);
    expect(find.text('Yaan'), findsOneWidget);
    // Drain pending timers from LogoPage transition
    await tester.pump(const Duration(seconds: 4));
  });
}
