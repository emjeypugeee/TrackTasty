import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fitness/theme/app_color.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<String> _routes = ['/home', '/chatbot', '/analytics', '/profile', '/forecasting'];

  int _selectedIndexFromLocation(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final List<String> routes = ['/home', '/chatbot', '/analytics', '/profile', '/forecasting'];

    // Exact match first
    final exactIndex = routes.indexWhere((route) => location == route);
    if (exactIndex >= 0) return exactIndex;

    // Check nested paths (e.g., '/home/subpage')
    for (int i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) {
        return i;
      }
    }

    // Default to home (index 0) if no match
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFromLocation(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'TrackTasty',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.titleText,
            fontSize: 30,
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Color(0xFF121212),
          child: ListView(
            children: [
              DrawerHeader(
                child: Center(
                  child: Image.asset('lib/images/TrackTastyLogo.png'),
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text(
                  'Edit Profile',
                  style: TextStyle(color: AppColors.primaryText),
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text(
                  'Edit Preference',
                  style: TextStyle(color: AppColors.primaryText),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text(
                  'Edit Goals',
                  style: TextStyle(color: AppColors.primaryText),
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text(
                  'Settings',
                  style: TextStyle(color: AppColors.primaryText),
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text(
                  'Settings',
                  style: TextStyle(color: AppColors.primaryText),
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text(
                  'Settings',
                  style: TextStyle(color: AppColors.primaryText),
                ),
              ),
              ListTile(
                leading: Icon(Icons.people_rounded),
                title: Text(
                  'About Us',
                  style: TextStyle(color: AppColors.primaryText),
                ),
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.primaryText),
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    actions: [
                      Row(
                        children: [
                          Expanded(child: CustomTextButton(title: 'Back', onTap: () {}, size: 20)),
                          Expanded(child: MyButtons(text: 'Log out', onTap: () {})),
                        ],
                      )
                    ],
                    backgroundColor: AppColors.containerBg,
                    title: Center(
                      child: Text(
                        'Log out?',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          context.go(_routes[index]);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.bottomNavBg,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        enableFeedback: false,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_rounded),
            label: 'Forecasting',
          ),
        ],
      ),

      //FAB
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        activeIcon: Icons.close,
        backgroundColor: Colors.grey[600],
        spacing: 20,
        buttonSize: const Size.fromRadius(35),
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        closeManually: false,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.camera_alt, color: Colors.white),
            label: 'Scan food',
            labelStyle: const TextStyle(color: Colors.white),
            labelBackgroundColor: Colors.grey[600],
            backgroundColor: Colors.grey[600],
            onTap: () async => await FirebaseAuth.instance.signOut(),
          ),
          SpeedDialChild(
            child: const Icon(Icons.food_bank, color: Colors.white),
            label: 'Add food manually',
            labelStyle: const TextStyle(color: Colors.white),
            labelBackgroundColor: Colors.grey[600],
            backgroundColor: Colors.grey[600],
          ),
          SpeedDialChild(
            child: const Icon(Icons.search, color: Colors.white),
            label: 'Search food',
            labelStyle: const TextStyle(color: Colors.white),
            labelBackgroundColor: Colors.grey[600],
            backgroundColor: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}
