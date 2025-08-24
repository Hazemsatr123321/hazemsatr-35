import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/screens/charity_screen.dart';
import 'package:smart_iraq/src/ui/screens/home_screen.dart';
import 'package:smart_iraq/src/ui/screens/profile_screen.dart';
import 'package:smart_iraq/src/ui/screens/smart_assistant_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.heart),
            label: 'الخيرية',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.sparkles),
            label: 'المساعد الذكي',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'ملفي',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        // Each CupertinoTabView will handle its own navigation stack
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (context) {
              return HomeScreen(productRepository: context.read<ProductRepository>());
            });
          case 1:
            return CupertinoTabView(builder: (context) {
              return const CharityScreen();
            });
          case 2:
            return CupertinoTabView(builder: (context) {
              return const SmartAssistantScreen();
            });
          case 3:
            return CupertinoTabView(builder: (context) {
              return const ProfileScreen();
            });
          default:
             return CupertinoTabView(builder: (context) {
              return HomeScreen(productRepository: context.read<ProductRepository>());
            });
        }
      },
    );
  }
}
