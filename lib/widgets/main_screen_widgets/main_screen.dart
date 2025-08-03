import 'package:fitness/widgets/main_screen_widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fitness/theme/app_color.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/main_screen_widgets/home_screen/macro_input.dart';
import 'package:fitness/pages/main_pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<String> _routes = [
    '/home',
    '/chatbot',
    '/analytics',
    '/profile',
    '/forecasting'
  ];

  int _selectedIndexFromLocation(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final List<String> routes = [
      '/home',
      '/chatbot',
      '/analytics',
      '/profile',
      '/forecasting'
    ];

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

    void _addFoodManually(BuildContext context) {
      // Controllers for user input
      final mealNameController = TextEditingController();
      final caloriesController = TextEditingController();
      final proteinController = TextEditingController();
      final carbsController = TextEditingController();
      final fatController = TextEditingController();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.loginPagesBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppColors.primaryText, width: 2),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Meal Name Input
                  TextFormField(
                    controller: mealNameController,
                    decoration: InputDecoration(
                      labelText: 'Meal Name',
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),

                  // Macros Input
                  Row(
                    children: [
                      // Calories Input
                      MacroInput(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        controller: caloriesController,
                      ),
                      const SizedBox(width: 10),
                      // Protein Input
                      MacroInput(
                        icon: Icons.set_meal,
                        label: 'Protein',
                        controller: proteinController,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Carbs Input
                      MacroInput(
                        icon: Icons.grass,
                        label: 'Carbs',
                        controller: carbsController,
                      ),
                      const SizedBox(width: 10),
                      // Fats Input
                      MacroInput(
                        icon: Icons.icecream,
                        label: 'Fats',
                        controller: fatController,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.primaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        /*
                       * SAVING THE FOOD LOG TO FIREBASE
                       */
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('food_logs')
                              .add({
                            'userId': user.uid, // Add user reference
                            'imageUrl': 'assets/images/meal.jpg',
                            'mealName': mealNameController.text,
                            'calories':
                                int.tryParse(caloriesController.text) ?? 0,
                            'protein':
                                int.tryParse(proteinController.text) ?? 0,
                            'carbs': int.tryParse(carbsController.text) ?? 0,
                            'fat': int.tryParse(fatController.text) ?? 0,
                            'loggedTime': DateTime.now(),
                          });
                        }
                        final meal = {
                          'imageUrl': 'assets/images/meal.jpg', // Default image
                          'mealName': mealNameController.text,
                          'calories':
                              int.tryParse(caloriesController.text) ?? 0,
                          'protein': int.tryParse(proteinController.text) ?? 0,
                          'carbs': int.tryParse(carbsController.text) ?? 0,
                          'fat': int.tryParse(fatController.text) ?? 0,
                          'loggedTime': DateTime.now(),
                        };

                        // Call the addMeal method in HomePage
                        homePageKey.currentState?.addMeal(meal);

                        Navigator.pop(context);
                      },
                      child: const Text('Add', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

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
      drawer: CustomDrawer(),
      body: _routes[selectedIndex] == '/home'
          ? HomePage(key: homePageKey) // Render HomePage when on the home route
          : widget.child,
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
            onTap: () {},
          ),
          SpeedDialChild(
            child: const Icon(Icons.food_bank, color: Colors.white),
            label: 'Add food manually',
            labelStyle: const TextStyle(color: Colors.white),
            labelBackgroundColor: Colors.grey[600],
            backgroundColor: Colors.grey[600],
            onTap: () => _addFoodManually(context),
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
