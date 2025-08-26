import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/services/notification_service.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/screens/splash_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Setup timeago locales
  timeago.setLocaleMessages('ar', timeago.ArMessages());

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
    return MaterialApp(
      title: 'العراق الذكي',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppTheme.goldAccent,
        scaffoldBackgroundColor: AppTheme.charcoalBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.goldAccent,
          secondary: AppTheme.goldAccent,
          surface: AppTheme.darkSurface,
          background: AppTheme.charcoalBackground,
        ),
        textTheme: AppTheme.darkCupertinoTheme.textTheme.textStyle != null
            ? GoogleFonts.tajawalTextTheme(
                ThemeData.dark().textTheme.apply(
                      bodyColor: AppTheme.lightTextColor,
                      displayColor: AppTheme.lightTextColor,
                    ),
              )
            : ThemeData.dark().textTheme,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
