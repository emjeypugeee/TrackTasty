import 'package:fitness/pages/main_pages/chat_bot.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:fitness/pages/main_pages/home_page.dart';
import 'package:fitness/pages/main_pages/analytics_page.dart';
import 'package:fitness/pages/main_pages/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index); // Jump to the selected page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          const HomePage(),
          const ChatBot(),
          const AnalyticsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF121212), // Dark background
        padding: const EdgeInsets.symmetric(
            vertical: 20, horizontal: 10), // Adjust padding
        child: GNav(
          selectedIndex: _selectedIndex,
          onTabChange: _onItemTapped,
          color: Colors.white,
          activeColor: Colors.white,
          tabBackgroundColor: const Color(0xFFE99797), // Active tab color
          gap: 8,
          iconSize: 25,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          tabs: const [
            GButton(icon: Icons.home, text: 'Home'),
            GButton(icon: Icons.message, text: 'Message'),
            GButton(icon: Icons.analytics, text: 'Analytics'),
            GButton(icon: Icons.person, text: 'Profile'),
          ],
        ),
      ),
    );
  }
}
