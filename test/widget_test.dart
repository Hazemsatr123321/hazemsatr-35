// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/providers/theme_provider.dart';
import 'package:smart_iraq/src/ui/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/widgets/filter_modal.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/models/chat_room_model.dart';
import 'package:smart_iraq/src/models/message_model.dart';

class FakeProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts({
    String? query,
    FilterOptions? filters,
  }) async {
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
    // Load .env file for tests
    await dotenv.load(fileName: ".env");

    // Initialize Supabase for testing
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  });

  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<SupabaseClient>(create: (_) => Supabase.instance.client),
          Provider<ChatRepository>(create: (_) => FakeChatRepository()),
          Provider<ProductRepository>(create: (_) => FakeProductRepository()),
        ],
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Verify that the splash screen is shown first.
    expect(find.text('سوق العراق الذكي'), findsOneWidget);
  });
}
