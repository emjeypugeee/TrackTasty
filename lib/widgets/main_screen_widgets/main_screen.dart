import 'package:fitness/pages/main_pages/analytics_page.dart';
import 'package:fitness/pages/main_pages/chat_bot.dart';
import 'package:fitness/pages/main_pages/food_page.dart';
import 'package:fitness/pages/main_pages/profile_page.dart';
import 'package:fitness/widgets/main_screen_widgets/custom_drawer.dart';
import 'package:fitness/widgets/main_screen_widgets/home_screen/food_input_sheet.dart';
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
  ];

  final List<Widget> _screens = [
    HomePage(key: homePageKey),
    const ChatBot(), // Make sure this uses AutomaticKeepAliveClientMixin
    AnalyticsPage(), // Replace with your actual analytics page
    ProfilePage(), // Replace with your actual achievements page
  ];
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
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFromLocation(context);
    DateTime? _lastPressed;

    //
    // MODAL BOTTOM SHEET
    //
    void _showFoodInputSheet({
      BuildContext? context,
      String? initialMealName,
      int? initialCalories,
      int? initialProtein,
      int? initialCarbs,
      int? initialFat,
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

    void _refreshHomePage() {
      if (homePageKey.currentState != null) {
        homePageKey.currentState!.setState(() {});
      }
    }

    //
    // ADD FOOD FUNCTION
    //
    void _addFoodManually(BuildContext context) {
      _showFoodInputSheet(
        context: context,
        onSubmit: (mealData) async {
          DateTime? _lastPressed;
          final now = DateTime.now();
          if (_lastPressed != null && now.difference(_lastPressed!) < Duration(seconds: 2)) {
            return; // Ignore if pressed within 2 seconds
          }
          _lastPressed = now;

          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final today = DateTime.now();
            final foodLogId = '${user.uid}_${today.year}-${today.month}-${today.day}';

            try {
              // Fetch existing food log for today or create a new one
              final foodLogDoc =
                  await FirebaseFirestore.instance.collection('food_logs').doc(foodLogId).get();

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

              // Update total macros
              final calories = mealData['calories'] ?? 0;
              final carbs = mealData['carbs'] ?? 0;
              final protein = mealData['protein'] ?? 0;
              final fat = mealData['fat'] ?? 0;

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
                'loggedTime': Timestamp.fromDate(DateTime.now()),
              });

              // Save updated food log data
              await FirebaseFirestore.instance
                  .collection('food_logs')
                  .doc(foodLogId)
                  .set(foodLogData);

              //
              // UPDATE ACHIEVEMENTS
              //
              try {
                // Get user's achievement document
                final achievementDoc =
                    FirebaseFirestore.instance.collection('user_achievements').doc(user.uid);

                final achievementSnapshot = await achievementDoc.get();
                final achievementData = achievementSnapshot.data() ?? {};

                // Update unique foods count
                final uniqueFoods = achievementData['unique_foods'] ?? 0;
                // For simplicity, we'll just increment by 1 each time
                // In a real app, you'd check if this is actually a unique food
                await achievementDoc
                    .set({'unique_foods': uniqueFoods + 1}, SetOptions(merge: true));

                // Update daily streak
                final lastLoggedDate = achievementData['last_logged_date'];
                final today = DateTime.now();
                final yesterday = today.subtract(Duration(days: 1));

                if (lastLoggedDate == null) {
                  // First time logging
                  await achievementDoc.set(
                      {'daily_streak': 1, 'last_logged_date': Timestamp.fromDate(today)},
                      SetOptions(merge: true));
                } else {
                  final lastDate = (lastLoggedDate as Timestamp).toDate();
                  if (lastDate.year == today.year &&
                      lastDate.month == today.month &&
                      lastDate.day == today.day) {
                    // Already logged today, no change to streak
                  } else if (lastDate.year == yesterday.year &&
                      lastDate.month == yesterday.month &&
                      lastDate.day == yesterday.day) {
                    // Logged yesterday, continue streak
                    final currentStreak = achievementData['daily_streak'] ?? 0;
                    await achievementDoc.set({
                      'daily_streak': currentStreak + 1,
                      'last_logged_date': Timestamp.fromDate(today)
                    }, SetOptions(merge: true));
                  } else {
                    // Broken streak, reset to 1
                    await achievementDoc.set(
                        {'daily_streak': 1, 'last_logged_date': Timestamp.fromDate(today)},
                        SetOptions(merge: true));
                  }
                }

                // Check if macros are perfect
                final userDoc =
                    await FirebaseFirestore.instance.collection('Users').doc(user.email).get();

                final userData = userDoc.data();
                if (userData != null) {
                  final targetCalories = userData['dailyCalories'] ?? 2000;
                  final targetProtein = userData['proteinGram'] ?? 150;
                  final targetCarbs = userData['carbsGram'] ?? 200;
                  final targetFat = userData['fatsGram'] ?? 70;

                  final totalCalories = foodLogData['totalCalories'];
                  final totalProtein = foodLogData['totalProtein'];
                  final totalCarbs = foodLogData['totalCarbs'];
                  final totalFat = foodLogData['totalFat'];

                  // Check if all macros are within 5% of targets
                  final caloriesPerfect = (totalCalories >= targetCalories * 0.95 &&
                      totalCalories <= targetCalories * 1.05);
                  final proteinPerfect = (totalProtein >= targetProtein * 0.95 &&
                      totalProtein <= targetProtein * 1.05);
                  final carbsPerfect =
                      (totalCarbs >= targetCarbs * 0.95 && totalCarbs <= targetCarbs * 1.05);
                  final fatPerfect = (totalFat >= targetFat * 0.95 && totalFat <= targetFat * 1.05);

                  if (caloriesPerfect && proteinPerfect && carbsPerfect && fatPerfect) {
                    // Update macro perfect days
                    final macroPerfectDays = achievementData['macro_perfect_days'] ?? 0;

                    // Check if we already counted today as a perfect day
                    final lastPerfectDate = achievementData['last_perfect_date'];
                    final today = DateTime.now();

                    if (lastPerfectDate == null ||
                        (lastPerfectDate as Timestamp).toDate().day != today.day) {
                      // First perfect day today
                      await achievementDoc.set({
                        'macro_perfect_days': macroPerfectDays + 1,
                        'last_perfect_date': Timestamp.fromDate(today)
                      }, SetOptions(merge: true));
                    }
                  }
                }
              } catch (e) {
                debugPrint('Error updating achievements: $e');
              }

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
    void editFoodManually(BuildContext context, Map<String, dynamic> existingFood) {
      _showFoodInputSheet(
        context: context,
        initialMealName: existingFood['mealName'],
        initialCalories: existingFood['calories'],
        initialProtein: existingFood['protein'],
        initialCarbs: existingFood['carbs'],
        initialFat: existingFood['fat'],
        isEditing: true,
        onSubmit: (updatedMealData) async {
          // Handle the update logic
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Use the original food's logged time to find the correct day
            final originalLoggedTime = existingFood['loggedTime'] as Timestamp;
            final originalDate = originalLoggedTime.toDate();
            final foodLogId =
                '${user.uid}_${originalDate.year}-${originalDate.month}-${originalDate.day}';

            try {
              final foodLogDoc =
                  await FirebaseFirestore.instance.collection('food_logs').doc(foodLogId).get();

              if (foodLogDoc.exists) {
                final foodLogData = foodLogDoc.data() as Map<String, dynamic>;
                final foods = List<Map<String, dynamic>>.from(foodLogData['foods'] ?? []);

                // Find the exact food item to update
                final index = foods.indexWhere((f) {
                  // Convert all values to the same data type for comparison
                  final fCalories =
                      (f['calories'] is int) ? f['calories'] : (f['calories'] as num).toInt();
                  final existingCalories = (existingFood['calories'] is int)
                      ? existingFood['calories']
                      : (existingFood['calories'] as num).toInt();

                  final fProtein =
                      (f['protein'] is int) ? f['protein'] : (f['protein'] as num).toInt();
                  final existingProtein = (existingFood['protein'] is int)
                      ? existingFood['protein']
                      : (existingFood['protein'] as num).toInt();

                  final fCarbs = (f['carbs'] is int) ? f['carbs'] : (f['carbs'] as num).toInt();
                  final existingCarbs = (existingFood['carbs'] is int)
                      ? existingFood['carbs']
                      : (existingFood['carbs'] as num).toInt();

                  final fFat = (f['fat'] is int) ? f['fat'] : (f['fat'] as num).toInt();
                  final existingFat = (existingFood['fat'] is int)
                      ? existingFood['fat']
                      : (existingFood['fat'] as num).toInt();

                  // Compare loggedTime by converting both to DateTime
                  final fTime = (f['loggedTime'] as Timestamp).toDate();
                  final existingTime = (existingFood['loggedTime'] as Timestamp).toDate();

                  return f['mealName'] == existingFood['mealName'] &&
                      fCalories == existingCalories &&
                      fProtein == existingProtein &&
                      fCarbs == existingCarbs &&
                      fFat == existingFat &&
                      fTime.millisecondsSinceEpoch == existingTime.millisecondsSinceEpoch;
                });

                if (index != -1) {
                  // Get the updated values
                  final updatedCalories = updatedMealData['calories'] ?? 0;
                  final updatedProtein = updatedMealData['protein'] ?? 0;
                  final updatedCarbs = updatedMealData['carbs'] ?? 0;
                  final updatedFat = updatedMealData['fat'] ?? 0;

                  // Get the original values
                  final originalCalories = existingFood['calories'] ?? 0;
                  final originalProtein = existingFood['protein'] ?? 0;
                  final originalCarbs = existingFood['carbs'] ?? 0;
                  final originalFat = existingFood['fat'] ?? 0;

                  // Calculate the difference
                  final caloriesDiff = updatedCalories - originalCalories;
                  final proteinDiff = updatedProtein - originalProtein;
                  final carbsDiff = updatedCarbs - originalCarbs;
                  final fatDiff = updatedFat - originalFat;

                  // Update totals by adding the difference
                  foodLogData['totalCalories'] = (foodLogData['totalCalories'] ?? 0) + caloriesDiff;
                  foodLogData['totalProtein'] = (foodLogData['totalProtein'] ?? 0) + proteinDiff;
                  foodLogData['totalCarbs'] = (foodLogData['totalCarbs'] ?? 0) + carbsDiff;
                  foodLogData['totalFat'] = (foodLogData['totalFat'] ?? 0) + fatDiff;

                  // Update the food item
                  foods[index] = {
                    ...foods[index],
                    'mealName': updatedMealData['mealName'] ?? existingFood['mealName'],
                    'calories': updatedCalories,
                    'protein': updatedProtein,
                    'carbs': updatedCarbs,
                    'fat': updatedFat,
                  };

                  foodLogData['foods'] = foods;

                  await FirebaseFirestore.instance
                      .collection('food_logs')
                      .doc(foodLogId)
                      .set(foodLogData);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Meal updated successfully')),
                  );

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Meal not found in food log')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Food log not found for this date')),
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
            label: 'Achievements', // Changed label to match your bottom nav
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
                      // image logging
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
                        } catch (e) {
                          debugPrint('Error updating image logs: $e');
                        }
                      }
                    }),
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
                  onTap: () async {
                    await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => FoodPage()));
                    _refreshHomePage(); // Refresh home page after returning
                  },
                ),
              ],
            )
          : null,
    );
  }
}
