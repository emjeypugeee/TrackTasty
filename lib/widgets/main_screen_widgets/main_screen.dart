import 'package:fitness/pages/main_pages/food_page.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/utils/macro_warning_utils.dart';
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
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime? _lastPressed;
  bool _isProcessing = false;
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
          editFoodManually(context, existingFood);
        },
      ),
      const ChatBot(),
      AnalyticsPage(),
      ProfilePage(),
    ];
  }

  Future<void> _handleCameraTap(BuildContext context) async {
    // Check camera permissions first
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    if (cameraStatus.isGranted) {
      final imagePath = await context.push('/camera');

      if (imagePath != null) {
        // Handle the captured image
        debugPrint('Image captured: $imagePath');

        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final achievementDoc = FirebaseFirestore.instance
                .collection('user_achievements')
                .doc(user.uid);

            final achievementSnapshot = await achievementDoc.get();
            final achievementData = achievementSnapshot.data() ?? {};
            final imageLogs = achievementData['image_logs'] ?? 0;

            await achievementDoc
                .set({'image_logs': imageLogs + 1}, SetOptions(merge: true));

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Food image captured successfully!')),
            );
          } catch (e) {
            debugPrint('Error updating image logs: $e');
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission is required to scan food')),
      );
    }
  }

  void _handleAddFoodTap(BuildContext context) {
    addFoodManually(context);
  }

  void _handleSearchFoodTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FoodPage()))
        .then((_) {
      refreshHomePage(); // Refresh home page after returning
    });
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
        final now = DateTime.now();
        // Prevent double tapping within 2 seconds
        if (_lastPressed != null &&
            now.difference(_lastPressed!) < Duration(seconds: 2)) {
          return;
        }
        _lastPressed = now;

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final today = DateTime.now();
          final foodLogId =
              '${user.uid}_${today.year}-${today.month}-${today.day}';

          try {
            // Get existing food log for today or create a new one
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

            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${mealData['mealName']} added to food log successfully!'),
                backgroundColor: AppColors.snackBarBgSaved,
              ),
            );

            await MacroWarningUtils.checkAndShowMacroWarnings(
              context,
              foodLogData,
            );
          } catch (e) {
            debugPrint('Error saving food log: $e');
            // Don't pop on error - let user see the error and try again
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving food: $e'),
                backgroundColor: Colors.red,
              ),
            );
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

              final index = foods.indexWhere((f) {
                final fTime = f['loggedTime'] as Timestamp;
                return fTime == originalLoggedTime;
              });

              if (index != -1) {
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

  void refreshHomePage() {
    if (homePageKey.currentState != null) {
      homePageKey.currentState!.setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFromLocation(context);
    DateTime? lastPressed;

    return Consumer<UserProvider>(builder: (context, userProvider, child) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          iconTheme: IconThemeData(color: Colors.white),
          title: Image.asset(
            'lib/images/Tracktasty-logo-long.png',
            height: 30,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
        ),
        drawer: CustomDrawer(),
        body: IndexedStack(
          index: selectedIndex,
          children: _screens, // This preserves the state of all screens
        ),
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
                    onTap: () => _handleCameraTap(context),
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.food_bank, color: Colors.white),
                    label: 'Add food manually',
                    labelStyle: const TextStyle(color: Colors.white),
                    labelBackgroundColor: Colors.grey[600],
                    backgroundColor: Colors.grey[600],
                    onTap: () => _handleAddFoodTap(context),
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.search, color: Colors.white),
                    label: 'Search food',
                    labelStyle: const TextStyle(color: Colors.white),
                    labelBackgroundColor: Colors.grey[600],
                    backgroundColor: Colors.grey[600],
                    onTap: () => _handleSearchFoodTap(context),
                  ),
                ],
              )
            : null,
      );
    });
  }
}
