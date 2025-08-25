import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_iraq/src/core/services/notification_service.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseClient>(create: (_) => Supabase.instance.client),
        Provider<ChatRepository>(create: (context) => SupabaseChatRepository(context.read<SupabaseClient>())),
        Provider<ProductRepository>(create: (context) => SupabaseProductRepository(context.read<SupabaseClient>())),
        ChangeNotifierProvider<NotificationService>(
          create: (context) => NotificationService(context.read<SupabaseClient>()),
        ),
      ],
      child: const SmartIraqApp(),
    ),
  );
}

class SmartIraqApp extends StatelessWidget {
  const SmartIraqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'العراق الذكي',
      theme: AppTheme.darkCupertinoTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
