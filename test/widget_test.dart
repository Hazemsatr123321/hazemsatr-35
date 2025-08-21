// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/ui/screens/auth/login_screen.dart';
import 'package:smart_iraq/src/ui/screens/auth/signup_screen.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/screens/product_detail_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    // Mock the shared_preferences plugin
    SharedPreferences.setMockInitialValues({});

    // Initialize Supabase for testing
    await Supabase.initialize(
      url: 'https://mfotgcymwpvbecqfghpg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mb3RnY3ltd3B2YmVjcWZnaHBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzNjE5NzAsImV4cCI6MjA3MDkzNzk3MH0.rYtnVSXRXx9VFFY9iPTWTNX5DN3VvrThaAbkV0hLQzs',
    );
  });

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

  testWidgets('Login screen validation and navigation', (WidgetTester tester) async {
    // Build the LoginScreen directly
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Tap the login button without entering any text
    await tester.tap(find.widgetWithText(ElevatedButton, 'دخول'));
    await tester.pump(); // Rebuild the widget to show validation errors

    // Verify that validation errors are shown
    expect(find.text('الرجاء إدخال بريد إلكتروني صحيح'), findsOneWidget);
    expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'دخول'));
    await tester.pump();
    expect(find.text('الرجاء إدخال بريد إلكتروني صحيح'), findsOneWidget);

    // Navigate to Signup screen
    await tester.tap(find.text('ليس لديك حساب؟ إنشاء حساب جديد'));
    await tester.pumpAndSettle();

    // Verify that we have navigated to the SignupScreen
    expect(find.byType(SignupScreen), findsOneWidget);
  });

  testWidgets('ProductCard shows product details correctly', (WidgetTester tester) async {
    // Create a dummy product
    final product = Product(
      id: '1',
      title: 'منتج اختباري',
      price: 1500.0,
      imageUrl: 'https://via.placeholder.com/150', // A placeholder image
    );

    // Build the ProductCard widget
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProductCard(product: product))));

    // Verify that the title and price are displayed
    expect(find.text('منتج اختباري'), findsOneWidget);
    expect(find.text('1500.0 د.ع'), findsOneWidget);

    // Verify that the image is being rendered
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Tapping ProductCard navigates to ProductDetailScreen', (WidgetTester tester) async {
    // Create a dummy product
    final product = Product(
      id: '1',
      title: 'منتج اختباري',
      price: 1500.0,
      imageUrl: 'https://via.placeholder.com/150',
      description: 'وصف اختباري للمنتج.',
    );

    // Build the ProductCard widget within a MaterialApp to handle navigation
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProductCard(product: product))));

    // Tap the card
    await tester.tap(find.byType(ProductCard));
    // Wait for the navigation animation to complete
    await tester.pumpAndSettle();

    // Verify that we have navigated to the ProductDetailScreen
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    // Verify that the detail screen shows the correct title
    expect(find.text('تفاصيل المنتج'), findsOneWidget);
  });
}
