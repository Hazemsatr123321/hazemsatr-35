import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/screens/add_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/home_screen.dart';
import 'package:smart_iraq/src/ui/screens/profile_screen.dart';
import 'package:smart_iraq/src/ui/screens/smart_assistant_screen.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_rooms_screen.dart';
import 'package:smart_iraq/src/ui/screens/ads_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool isGuest;
  const MainNavigationScreen({super.key, this.isGuest = false});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(productRepository: context.read<ProductRepository>(), isGuest: widget.isGuest),
      const AdsScreen(),
      ChatRoomsScreen(chatRepository: context.read<ChatRepository>()),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: StylishBottomBar(
        option: BubbleBarOptions(
          barStyle: BubbleBarStyle.horizotnal,
          bubbleFillStyle: BubbleFillStyle.fill,
          opacity: 0.3,
        ),
        items: [
          _buildNavItem(Icons.home_rounded, 'الرئيسية', isGuest: widget.isGuest, index: 0),
          _buildNavItem(Icons.grid_view_rounded, 'الإعلانات', isGuest: widget.isGuest, index: 1),
          _buildNavItem(Icons.chat_bubble_rounded, 'الرسائل', isGuest: widget.isGuest, index: 2),
          _buildNavItem(Icons.person_rounded, 'حسابي', isGuest: widget.isGuest, index: 3),
        ],
        fabLocation: StylishBarFabLocation.center,
        hasNotch: true,
        currentIndex: _selectedIndex,
        backgroundColor: AppTheme.darkSurface,
        onTap: (index) {
          if (widget.isGuest && (index == 2 || index == 3)) {
            // Optionally, show a login prompt
            return;
          }
          setState(() {
            _selectedIndex = index;
            _pageController.jumpToPage(index);
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddProductScreen()));
        },
        backgroundColor: AppTheme.goldAccent,
        child: const Icon(Icons.add, color: AppTheme.charcoalBackground),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: pages,
          ),
          Positioned(
            left: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'assistant_fab', // Use a unique hero tag
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SmartAssistantScreen()));
              },
              backgroundColor: AppTheme.darkSurface,
              child: const Icon(Icons.auto_awesome, color: AppTheme.goldAccent),
            ),
          ),
        ],
      ),
    );
  }

  BottomBarItem _buildNavItem(IconData icon, String title, {bool isGuest = false, required int index}) {
    final bool isDisabled = isGuest && (index == 2 || index == 3);
    return BottomBarItem(
      icon: Icon(icon, color: isDisabled ? AppTheme.secondaryTextColor.withOpacity(0.5) : null),
      title: Text(title),
      selectedColor: AppTheme.goldAccent,
      unSelectedColor: isDisabled ? AppTheme.secondaryTextColor.withOpacity(0.5) : AppTheme.secondaryTextColor,
      backgroundColor: AppTheme.goldAccent,
    );
  }
}
