import 'package:fitness/pages/main_pages/food_page.dart';
import 'package:fitness/widgets/main_screen_widgets/custom_drawer.dart';
import 'package:fitness/widgets/main_screen_widgets/home_screen/food_input_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/pages/main_pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/utils/achievement_utils.dart';
import 'package:fitness/pages/main_pages/analytics_page.dart';
import 'package:fitness/pages/main_pages/chat_bot.dart';
import 'package:fitness/pages/main_pages/profile_page.dart';
import 'package:permission_handler/permission_handler.dart';

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
  ];

  late List<Widget> _screens;
  int _selectedIndexFromLocation(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final List<String> routes = [
      '/home',
      '/chatbot',
      '/analytics',
      '/profile',
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
  void initState() {
    super.initState();
    _screens = [
      HomePage(
        key: homePageKey,
        onEditMeal: (context, existingFood) {
          debugPrint('editFoodManually callback triggered');
          editFoodManually(context, existingFood); // Call your actual method
        },
      ),
      const ChatBot(), // Make sure this uses AutomaticKeepAliveClientMixin
      AnalyticsPage(), // Replace with your actual analytics page
      ProfilePage(), // Replace with your actual achievements page
    ];
  }

  //
  // MODAL BOTTOM SHEET
  //
  void showFoodInputSheet({
    BuildContext? context,
    String? initialMealName,
    double? initialCalories,
    double? initialProtein,
    double? initialCarbs,
    double? initialFat,
    bool isEditing = false,
    required Function(Map<String, dynamic>) onSubmit,
  }) {
    showModalBottomSheet(
      context: context!,
      isScrollControlled: true,
      backgroundColor: AppColors.loginPagesBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.primaryText, width: 2),
      ),
      builder: (context) {
        return FoodInputSheet(
          initialMealName: initialMealName,
          initialCalories: initialCalories,
          initialProtein: initialProtein,
          initialCarbs: initialCarbs,
          initialFat: initialFat,
          onSubmit: onSubmit,
          isEditing: isEditing,
        );
      },
    );
  }

  //
  // ADD FOOD FUNCTION
  //
  void addFoodManually(BuildContext context) {
    showFoodInputSheet(
      context: context,
      onSubmit: (mealData) async {
        DateTime? lastPressed;
        final now = DateTime.now();
        if (lastPressed != null &&
            now.difference(lastPressed) < Duration(seconds: 2)) {
          return; // Ignore if pressed within 2 seconds
        }
        lastPressed = now;

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final today = DateTime.now();
          final foodLogId =
              '${user.uid}_${today.year}-${today.month}-${today.day}';

          try {
            // Fetch existing food log for today or create a new one
            final foodLogDoc = await FirebaseFirestore.instance
                .collection('food_logs')
                .doc(foodLogId)
                .get();

            Map<String, dynamic> foodLogData = {
              'userId': user.uid,
              'date': Timestamp.fromDate(today),
              'totalCalories': 0,
              'totalCarbs': 0,
              'totalProtein': 0,
              'totalFat': 0,
              'foods': [],
            };

            // If the document exists, update the data
            if (foodLogDoc.exists && foodLogDoc.data() != null) {
              foodLogData = foodLogDoc.data() as Map<String, dynamic>;
            }

            // Update total macros (convert to double)
            final calories = (mealData['calories'] ?? 0).toDouble();
            final carbs = (mealData['carbs'] ?? 0).toDouble();
            final protein = (mealData['protein'] ?? 0).toDouble();
            final fat = (mealData['fat'] ?? 0).toDouble();

            foodLogData['totalCalories'] += calories;
            foodLogData['totalCarbs'] += carbs;
            foodLogData['totalProtein'] += protein;
            foodLogData['totalFat'] += fat;

            // Add the new food item
            foodLogData['foods'].add({
              'mealName': mealData['mealName'] ?? '',
              'calories': calories,
              'carbs': carbs,
              'protein': protein,
              'fat': fat,
              'servingSize': mealData['servingSize'] ?? '',
              'adjustmentType': mealData['adjustmentType'] ?? 'percent',
              'adjustmentValue': mealData['adjustmentValue'] ?? 100.0,
              'loggedTime': Timestamp.fromDate(DateTime.now()),
            });

            // Save updated food log data
            await FirebaseFirestore.instance
                .collection('food_logs')
                .doc(foodLogId)
                .set(foodLogData);

            // Update achievement
            await AchievementUtils.updateAchievementsOnFoodLog(
                userId: user.uid,
                foodLogData: foodLogData,
                newMealName: mealData['mealName'] ?? '',
                isImageLog: false,
                context: context);

            Navigator.pop(context);
          } catch (e) {
            debugPrint('Error saving food log: $e');
          }
        }
      },
    );
  }

  //
  // EDIT FOOD FUNCTION
  //
  void editFoodManually(
      BuildContext context, Map<String, dynamic> existingFood) {
    // Use the safeToDouble function as it's good practice
    double? safeToDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    showFoodInputSheet(
      context: context,
      initialMealName: existingFood['mealName'],
      initialCalories: safeToDouble(existingFood['calories']),
      initialProtein: safeToDouble(existingFood['protein']),
      initialCarbs: safeToDouble(existingFood['carbs']),
      initialFat: safeToDouble(existingFood['fat']),
      isEditing: true,
      onSubmit: (updatedMealData) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Use the original food's logged time to find the correct day
          final originalLoggedTime = existingFood['loggedTime'] as Timestamp;
          final originalDate = originalLoggedTime.toDate();
          final foodLogId =
              '${user.uid}_${originalDate.year}-${originalDate.month}-${originalDate.day}';

          try {
            final foodLogDoc = await FirebaseFirestore.instance
                .collection('food_logs')
                .doc(foodLogId)
                .get();

            if (foodLogDoc.exists) {
              final foodLogData = foodLogDoc.data() as Map<String, dynamic>;
              final foods =
                  List<Map<String, dynamic>>.from(foodLogData['foods'] ?? []);

              // Find the exact food item to update using ONLY the loggedTime
              final index = foods.indexWhere((f) {
                final fTime = f['loggedTime'] as Timestamp;
                return fTime == originalLoggedTime;
              });

              if (index != -1) {
                // Convert all values to double for consistent math
                final updatedCalories =
                    (updatedMealData['calories'] as num).toDouble();
                final updatedProtein =
                    (updatedMealData['protein'] as num).toDouble();
                final updatedCarbs =
                    (updatedMealData['carbs'] as num).toDouble();
                final updatedFat = (updatedMealData['fat'] as num).toDouble();

                final originalCalories =
                    (foods[index]['calories'] as num).toDouble();
                final originalProtein =
                    (foods[index]['protein'] as num).toDouble();
                final originalCarbs = (foods[index]['carbs'] as num).toDouble();
                final originalFat = (foods[index]['fat'] as num).toDouble();

                // Calculate the difference
                final caloriesDiff = updatedCalories - originalCalories;
                final proteinDiff = updatedProtein - originalProtein;
                final carbsDiff = updatedCarbs - originalCarbs;
                final fatDiff = updatedFat - originalFat;

                // Update totals by adding the difference
                foodLogData['totalCalories'] =
                    (foodLogData['totalCalories'] ?? 0) + caloriesDiff;
                foodLogData['totalProtein'] =
                    (foodLogData['totalProtein'] ?? 0) + proteinDiff;
                foodLogData['totalCarbs'] =
                    (foodLogData['totalCarbs'] ?? 0) + carbsDiff;
                foodLogData['totalFat'] =
                    (foodLogData['totalFat'] ?? 0) + fatDiff;

                // Update the food item
                foods[index] = {
                  ...foods[index],
                  'mealName': updatedMealData['mealName'],
                  'calories': updatedCalories,
                  'protein': updatedProtein,
                  'carbs': updatedCarbs,
                  'fat': updatedFat,
                  'servingSize': updatedMealData['servingSize'],
                  'adjustmentType': updatedMealData['adjustmentType'],
                  'adjustmentValue': updatedMealData['adjustmentValue'],
                };

                foodLogData['foods'] = foods;

                await FirebaseFirestore.instance
                    .collection('food_logs')
                    .doc(foodLogId)
                    .set(foodLogData);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal updated successfully')),
                );

                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal not found in food log')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Food log not found for this date')),
              );
            }
          } catch (e) {
            debugPrint('Error updating food: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating meal: $e')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFromLocation(context);
    DateTime? lastPressed;

    void refreshHomePage() {
      if (homePageKey.currentState != null) {
        homePageKey.currentState!.setState(() {});
      }
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
      body: IndexedStack(
        index: selectedIndex,
        children: _screens, // This preserves the state of all screens
      ),
      /*body: _routes[selectedIndex] == '/home'
          ? HomePage(
              key: homePageKey,
              onEditMeal:
                  editFoodManually) // Render HomePage when on the home route
          : widget.child,*/
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          context.go(_routes[index]);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.bottomNavBg,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withValues(alpha: 0.6),
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
            icon: Icon(Icons.star),
            label: 'Achievements',
          ),
        ],
      ),

      //FAB
      floatingActionButton: _routes[selectedIndex] == '/home'
          ? SpeedDial(
              icon: Icons.add,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              activeIcon: Icons.close,
              backgroundColor: const Color.fromARGB(120, 117, 117, 117),
              spacing: 20,
              buttonSize: const Size.fromRadius(30),
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
                  onTap: () async {
                    // Check camera permissions first
                    var cameraStatus = await Permission.camera.status;
                    if (!cameraStatus.isGranted) {
                      cameraStatus = await Permission.camera.request();
                    }

                    if (cameraStatus.isGranted) {
                      // Open camera screen and wait for result
                      final imagePath = await context.push('/camera');

                      if (imagePath != null) {
                        // Handle the captured image
                        print('Image captured: $imagePath');

                        // You can now process this image for food recognition
                        // For now, let's just update the achievement count
                        final User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          try {
                            final achievementDoc = FirebaseFirestore.instance
                                .collection('user_achievements')
                                .doc(user.uid);

                            final achievementSnapshot =
                                await achievementDoc.get();
                            final achievementData =
                                achievementSnapshot.data() ?? {};
                            final imageLogs =
                                achievementData['image_logs'] ?? 0;

                            await achievementDoc.set(
                                {'image_logs': imageLogs + 1},
                                SetOptions(merge: true));

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Food image captured successfully!')),
                            );
                          } catch (e) {
                            debugPrint('Error updating image logs: $e');
                          }
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Camera permission is required to scan food')),
                      );
                    }
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.food_bank, color: Colors.white),
                  label: 'Add food manually',
                  labelStyle: const TextStyle(color: Colors.white),
                  labelBackgroundColor: Colors.grey[600],
                  backgroundColor: Colors.grey[600],
                  onTap: () => addFoodManually(context),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.search, color: Colors.white),
                  label: 'Search food',
                  labelStyle: const TextStyle(color: Colors.white),
                  labelBackgroundColor: Colors.grey[600],
                  backgroundColor: Colors.grey[600],
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => FoodPage()));
                    refreshHomePage(); // Refresh home page after returning
                  },
                ),
              ],
            )
          : null,
    );
  }
}
