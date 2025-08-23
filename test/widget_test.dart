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
import 'package:smart_iraq/src/ui/screens/add_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/home_screen.dart';
import 'package:smart_iraq/src/ui/screens/profile_screen.dart';
import 'package:smart_iraq/src/ui/screens/edit_product_screen.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_rooms_screen.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/models/chat_room_model.dart';
import 'package:smart_iraq/src/models/message_model.dart';
import 'package:smart_iraq/src/ui/screens/charity_screen.dart';
import 'package:smart_iraq/src/ui/screens/dashboard_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class FakeProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts({
    String? query,
    String? category,
    bool? sortAscending,
  }) async {
    // Return an empty list to avoid breaking the UI,
    // as this test doesn't care about the results.
    return [];
  }
}

class FakeChatRepository implements ChatRepository {
  @override
  Future<List<ChatRoom>> getChatRooms() async {
    return [];
  }

  @override
  Stream<List<Message>> getMessagesStream(String roomId) {
    return Stream.value([]);
  }

  @override
  Future<void> sendMessage(String roomId, String content) async {}

  @override
  Future<String> findOrCreateChatRoom(String otherUserId) async {
    return 'fake_room_id';
  }
}


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
      userId: 'dummy_user_id',
      category: 'Test Category',
      viewCount: 10,
      messageCount: 2,
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
      userId: 'dummy_user_id',
      category: 'Test Category',
      viewCount: 10,
      messageCount: 2,
    );

    // Build the ProductCard widget within a MaterialApp to handle navigation
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProductCard(product: product))));

    // Tap the card
    await tester.tap(find.byType(ProductCard));
    // Wait for the navigation animation to complete
    await tester.pumpAndSettle();

    // Verify that we have navigated to the ProductDetailScreen by finding its key
    expect(find.byKey(const Key('productDetailScreen')), findsOneWidget);
  });

  testWidgets('AddProductScreen shows validation errors', (WidgetTester tester) async {
    // Build the AddProductScreen directly
    await tester.pumpWidget(const MaterialApp(home: AddProductScreen()));

    // Tap the save button without entering any text
    final saveButton = find.byKey(const Key('saveProductButton'));
    // We need to scroll down to find the button
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, -500));
    await tester.pump();

    await tester.tap(saveButton);
    await tester.pump(); // Rebuild the widget to show validation errors

    // Verify that validation errors are shown for all fields
    expect(find.text('الرجاء إدخال عنوان للإعلان'), findsOneWidget);
    expect(find.text('الرجاء إدخال وصف للإعلان'), findsOneWidget);
    expect(find.text('الرجاء إدخال سعر صحيح'), findsOneWidget);
    expect(find.text('الرجاء اختيار فئة للإعلان'), findsOneWidget);
  });

  testWidgets('HomeScreen builds without crashing', (WidgetTester tester) async {
    // This is a simplified test to ensure the complex FutureBuilder setup doesn't crash.
    await tester.pumpWidget(MaterialApp(home: HomeScreen(productRepository: FakeProductRepository())));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('ProductCard shows delete button when showControls is true', (WidgetTester tester) async {
    // Create a dummy product
    final product = Product(
      id: '1',
      title: 'منتج اختباري',
      price: 1500.0,
      imageUrl: 'https://via.placeholder.com/150',
      userId: 'dummy_user_id',
      category: 'Test Category',
    );

    // Build the ProductCard widget with showControls set to true
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProductCard(
          product: product,
          showControls: true,
          onDelete: () {},
        ),
      ),
    ));

    // Verify that the delete button is present
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('ProductCard shows edit button when showControls is true', (WidgetTester tester) async {
    // Create a dummy product
    final product = Product(
      id: '1',
      title: 'منتج اختباري',
      price: 1500.0,
      imageUrl: 'https://via.placeholder.com/150',
      userId: 'dummy_user_id',
      category: 'Test Category',
    );

    // Build the ProductCard widget with showControls set to true
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProductCard(
          product: product,
          showControls: true,
          onEdit: () {},
        ),
      ),
    ));

    // Verify that the edit button is present
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('EditProductScreen is pre-filled with product data and category', (WidgetTester tester) async {
    // Create a dummy product
    final product = Product(
      id: '1',
      title: 'منتج اختباري',
      price: 1500.0,
      imageUrl: 'https://via.placeholder.com/150',
      description: 'وصف اختباري للمنتج.',
      userId: 'dummy_user_id',
      category: 'إلكترونيات', // Use a category from the predefined list
    );

    // Build the EditProductScreen
    await tester.pumpWidget(MaterialApp(home: EditProductScreen(product: product)));

    // Verify that the fields are pre-filled
    expect(find.text('منتج اختباري'), findsOneWidget);
    expect(find.text('وصف اختباري للمنتج.'), findsOneWidget);
    expect(find.text('1500.0'), findsOneWidget);

    // Verify that the category dropdown is pre-filled
    expect(find.widgetWithText(DropdownButtonFormField<String>, 'إلكترونيات'), findsOneWidget);
  });

  testWidgets('HomeScreen search UI toggles correctly', (WidgetTester tester) async {
    // Build the HomeScreen
    await tester.pumpWidget(MaterialApp(home: HomeScreen(productRepository: FakeProductRepository())));

    // Initially, the normal AppBar is shown
    expect(find.text('السوق - العراق الذكي'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // Tap the search icon to enter search mode
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    // Verify the search AppBar is shown
    expect(find.text('السوق - العراق الذكي'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Tap the back button to exit search mode
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    // Verify the normal AppBar is shown again
    expect(find.text('السوق - العراق الذكي'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('AddProductScreen shows image picker UI', (WidgetTester tester) async {
    // Build the AddProductScreen
    await tester.pumpWidget(const MaterialApp(home: AddProductScreen()));

    // Verify that the image picker placeholder is shown
    expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
    expect(find.text('أضف صورة'), findsOneWidget);
  });

  testWidgets('ChatRoomsScreen shows login message when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ChatRoomsScreen(chatRepository: FakeChatRepository())));
    // Let the FutureBuilder resolve
    await tester.pumpAndSettle();
    expect(find.text('الرجاء تسجيل الدخول لعرض المحادثات.'), findsOneWidget);
  });

  testWidgets('ChatScreen shows basic UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ChatScreen(
      roomId: 'test_room',
      chatRepository: FakeChatRepository(),
    )));

    expect(find.text('المحادثة'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Tapping chat button on HomeScreen navigates to ChatRoomsScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(productRepository: FakeProductRepository())));

    await tester.tap(find.byIcon(Icons.chat));
    await tester.pumpAndSettle();

    expect(find.byType(ChatRoomsScreen), findsOneWidget);
  });

  testWidgets('ChatScreen shows AI assistant button', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ChatScreen(
      roomId: 'test_room',
      chatRepository: FakeChatRepository(),
    )));

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('HomeScreen filter button opens filter sheet', (WidgetTester tester) async {
    // Build the HomeScreen
    await tester.pumpWidget(MaterialApp(home: HomeScreen(productRepository: FakeProductRepository())));

    // Tap the filter icon button
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle(); // Wait for bottom sheet to animate up

    // Verify that the filter sheet is shown
    expect(find.text('الفلترة والفرز'), findsOneWidget);
    expect(find.text('الفرز حسب السعر'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'تطبيق'), findsOneWidget);
  });

  testWidgets('SignupScreen has referral code field', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
    expect(find.widgetWithText(TextFormField, 'كود الإحالة (اختياري)'), findsOneWidget);
  });

  testWidgets('Tapping charity button on HomeScreen navigates to CharityScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(productRepository: FakeProductRepository())));

    await tester.tap(find.byIcon(Icons.volunteer_activism));
    await tester.pumpAndSettle();

    expect(find.byType(CharityScreen), findsOneWidget);
    expect(find.text('دعم القضايا الخيرية'), findsOneWidget);
  });

  // This test is commented out because it requires significant mocking of the Supabase client
  // to simulate an admin user session, which is beyond the current test setup.
  // testWidgets('ProfileScreen shows admin controls for admin user', (WidgetTester tester) async {
  //   // Mock a profile response
  //   final mockProfile = Profile(id: 'admin_id', role: 'admin', referralCode: 'ADMIN', referralCount: 0);

  //   // How to inject this into the ProfileScreen is the challenge.
  //   // Without a proper dependency injection and mocking framework, this is difficult.

  //   await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
  //   await tester.pumpAndSettle();

  //   // This would be the ideal assertion
  //   expect(find.text('إدارة الإعلانات الخارجية'), findsOneWidget);
  // });

  testWidgets('DashboardScreen shows error when not logged in', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pumpAndSettle(); // Let the future fail
    expect(find.textContaining('User not logged in'), findsOneWidget);
  });

  testWidgets('AddProductScreen has suggest price button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddProductScreen()));
    expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);
  });

  testWidgets('EditProductScreen has suggest price button', (WidgetTester tester) async {
    final product = Product(id: '1', title: 'test', price: 100, imageUrl: '', userId: '123');
    await tester.pumpWidget(MaterialApp(home: EditProductScreen(product: product)));
    expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);
  });
}
