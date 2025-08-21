// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smart_iraq/main.dart';

void main() {
  testWidgets('Splash screen navigates to Login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartIraqApp());

    // Verify that the splash screen is shown first.
    expect(find.text('جاري التحميل...'), findsOneWidget);

    // Wait for the navigation to complete.
    // The duration should be longer than the delay in SplashScreen.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that we have navigated to the LoginScreen.
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('جاري التحميل...'), findsNothing);
  });
}
