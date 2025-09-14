import 'dart:async';

import 'package:fitness/widgets/main_screen_widgets/home_screen/circular_nutrition_progres.dart';
import 'package:fitness/widgets/main_screen_widgets/home_screen/meals_container.dart';
import 'package:fitness/widgets/main_screen_widgets/food_page_screen/meal_container.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

final GlobalKey<_HomePageState> homePageKey = GlobalKey<_HomePageState>();

class HomePage extends StatefulWidget {
  final Function(BuildContext, Map<String, dynamic>)? onEditMeal;

  const HomePage({
    super.key,
    this.onEditMeal,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

// state holder class
class MealsState extends ChangeNotifier {
  List<Map<String, dynamic>> _meals = [];

  List<Map<String, dynamic>> get meals => _meals;

  void setMeals(List<Map<String, dynamic>> meals) {
    _meals = meals;
    notifyListeners();
  }
}

class _HomePageState extends State<HomePage> {
  late List<DateTime> days;
  int selectedIndex = 6;
  late DateTime selectedDay;

  // Nutrition data state
  Map<String, dynamic>? _nutritionData;
  // bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _foodLogSubscription;

  void refreshData() {
    _loadNutritionData();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    selectedIndex = 6;
    selectedDay = days[selectedIndex];
    _loadNutritionData();

    /* backfill current weight if no history exists
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.email)
            .get();

        if (userDoc.exists && userDoc.data()?['weight'] != null) {
          final today = DateTime.now();
          final weightValue = userDoc.data()!['weight'];
          double? weight;

          // Handle different data types for weight
          if (weightValue is String) {
            weight = double.tryParse(weightValue);
          } else if (weightValue is int) {
            weight = weightValue.toDouble();
          } else if (weightValue is double) {
            weight = weightValue;
          }

          if (weight != null) {
            // Create document ID with format: ${userId}_${date}
            final docId =
                '${user.uid}_${DateFormat('yyyy-MM-dd').format(today)}';

            await FirebaseFirestore.instance
                .collection('weight_history')
                .doc(docId)
                .set({
              'userId': user.uid, // Still include userId for querying
              'weight': weight,
              'date': Timestamp.fromDate(today),
            }, SetOptions(merge: true));

            debugPrint('Successfully saved weight history for $docId');
          }
        }
      } catch (e) {
        debugPrint('Error in weight history initialization: $e');
      }
    }
    );*/
  }

  Future<void> _loadNutritionData() async {
    //setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    /*if (user == null) {
      setState(() => _isLoading = false);
      return;
    }*/

    // Cancel previous subscription
    _foodLogSubscription?.cancel();

    _foodLogSubscription = FirebaseFirestore.instance
        .collection('food_logs')
        .where('userId', isEqualTo: user?.uid)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(selectedDay.year, selectedDay.month, selectedDay.day)))
        .where('date',
            isLessThan: Timestamp.fromDate(DateTime(
                selectedDay.year, selectedDay.month, selectedDay.day + 1)))
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final foodLog = snapshot.docs.first.data();
        setState(() {
          _nutritionData = {
            'totalCalories': foodLog['totalCalories'] ?? 0,
            'totalProtein': foodLog['totalProtein'] ?? 0,
            'totalCarbs': foodLog['totalCarbs'] ?? 0,
            'totalFat': foodLog['totalFat'] ?? 0,
          };
          //_isLoading = false;
        });
      } else {
        setState(() {
          _nutritionData = {
            'totalCalories': 0,
            'totalProtein': 0,
            'totalCarbs': 0,
            'totalFat': 0,
          };
          //_isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _foodLogSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Calendar Section
              _buildCalendarSection(),

              // nutrition progress bar section
              /*
               *  +++++++++++++++++++++++++++++++
               *  NUTRITION PROGRESS BARS SECTION
               *  +++++++++++++++++++++++++++++++
               */
              const SizedBox(height: 20),
              _buildNutritionProgressSection(),
              /*
               *  +++++++++++++++++
               *  MEALS LOG SECTION
               *  +++++++++++++++++
               */
              const SizedBox(height: 20),
              const Row(
                children: [
                  Text(
                    'Meals:',
                    textAlign: TextAlign.start,
                    style: TextStyle(color: Colors.white, fontSize: 35),
                  ),
                ],
              ),
              _buildMealsList(),
            ],
          ),
        ),
      ),
    );
  }

  /*
   *  +++++++++++++++++
   *  CALENDAR SECTION
   *  +++++++++++++++++
   */
  Widget _buildCalendarSection() {
    final DateFormat dayFormat = DateFormat('E');
    final DateFormat dateFormat = DateFormat('d');
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
                selectedDay = days[index];
              });
              _loadNutritionData();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayFormat.format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionProgressSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseAuth.instance.currentUser?.email)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError ||
            !userSnapshot.hasData ||
            !userSnapshot.data!.exists) {
          return const Text(
            'Error fetching user data.',
            style: TextStyle(color: Colors.red),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final calorieGoal = (userData['dailyCalories'] ?? 2000).toInt();
        final proteinGoal = (userData['proteinGram'] ?? 100).toInt();
        final carbsGoal = (userData['carbsGram'] ?? 250).toInt();
        final fatGoal = (userData['fatGram'] ?? 70).toInt();

        final totalCalories = _nutritionData?['totalCalories'] ?? 0;
        final totalProtein = _nutritionData?['totalProtein'] ?? 0;
        final totalCarbs = _nutritionData?['totalCarbs'] ?? 0;
        final totalFat = _nutritionData?['totalFat'] ?? 0;

        return Column(
          children: [
            Row(
              children: [
                CircularNutritionProgres(
                  key: ValueKey('calories-$selectedDay'),
                  macroType: 'Calories',
                  progressColor: AppColors.caloriesColor,
                  value: '${(totalCalories - calorieGoal).abs().toInt()}g',
                  label: totalCalories > calorieGoal
                      ? 'Calories over'
                      : 'Calories remaining',
                  selectedDate: selectedDay,
                ),
                const SizedBox(width: 10),
                CircularNutritionProgres(
                  key: ValueKey('protein-$selectedDay'),
                  macroType: 'Protein',
                  progressColor: AppColors.proteinColor,
                  value: '${(totalProtein - proteinGoal).abs().toInt()}g',
                  label: totalProtein > proteinGoal
                      ? 'Protein over'
                      : 'Protein remaining',
                  selectedDate: selectedDay,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircularNutritionProgres(
                  key: ValueKey('carbs-$selectedDay'),
                  macroType: 'Carbs',
                  progressColor: AppColors.carbsColor,
                  value: '${(totalCarbs - carbsGoal).abs().toInt()}g',
                  label:
                      totalCarbs > carbsGoal ? 'Carbs over' : 'Carbs remaining',
                  selectedDate: selectedDay,
                ),
                const SizedBox(width: 10),
                CircularNutritionProgres(
                  key: ValueKey('fat-$selectedDay'),
                  macroType: 'Fat',
                  progressColor: AppColors.fatColor,
                  value: '${(totalFat - fatGoal).abs().toInt()}g',
                  label: totalFat > fatGoal ? 'Fat over' : 'Fat remaining',
                  selectedDate: selectedDay,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMealsList() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Please log in to see your meals.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('food_logs')
              .where('userId', isEqualTo: user.uid)
              .where('date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                      selectedDay.year, selectedDay.month, selectedDay.day)))
              .where('date',
                  isLessThan: Timestamp.fromDate(DateTime(selectedDay.year,
                      selectedDay.month, selectedDay.day + 1)))
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No meals logged yet.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final foodLog =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final foods =
                List<Map<String, dynamic>>.from(foodLog['foods'] ?? []);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...foods.map((food) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MealsContainer(
                      mealName: food['mealName'] ?? '',
                      calories: (food['calories'] ?? 0).toDouble(),
                      protein: (food['protein'] ?? 0).toDouble(),
                      carbs: (food['carbs'] ?? 0).toDouble(),
                      fat: (food['fat'] ?? 0).toDouble(),
                      servingSize: food['servingSize'] ?? '',
                      adjustmentType: food['adjustmentType'] ?? 'percent',
                      adjustmentValue:
                          (food['adjustmentValue'] ?? 100.0).toDouble(),
                      loggedTime: (food['loggedTime'] as Timestamp).toDate(),
                      onEdit: () => _handleEditMeal(food),
                      onDelete: () => _handleDeleteMeal(food),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _handleEditMeal(Map<String, dynamic> food) {
    if (widget.onEditMeal != null) {
      widget.onEditMeal!(context, food);
    }
    refreshData();
  }

  void _handleDeleteMeal(Map<String, dynamic> food) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Meal', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${food['mealName']}"?',
            style: TextStyle(color: Colors.white70)),
        backgroundColor: Colors.grey[900],
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final today = DateTime.now();
    final foodLogId = '${user.uid}_${today.year}-${today.month}-${today.day}';

    try {
      final foodLogDoc = await FirebaseFirestore.instance
          .collection('food_logs')
          .doc(foodLogId)
          .get();

      if (foodLogDoc.exists) {
        final foodLogData = foodLogDoc.data() as Map<String, dynamic>;
        final foods =
            List<Map<String, dynamic>>.from(foodLogData['foods'] ?? []);

        // Find the food item to delete using a more flexible comparison
        final index = foods.indexWhere((f) {
          // Convert all values to the same data type for comparison
          final fCalories = (f['calories'] is int)
              ? f['calories']
              : (f['calories'] as num).toInt();
          final foodCalories = (food['calories'] is int)
              ? food['calories']
              : (food['calories'] as num).toInt();

          final fProtein = (f['protein'] is int)
              ? f['protein']
              : (f['protein'] as num).toInt();
          final foodProtein = (food['protein'] is int)
              ? food['protein']
              : (food['protein'] as num).toInt();

          final fCarbs =
              (f['carbs'] is int) ? f['carbs'] : (f['carbs'] as num).toInt();
          final foodCarbs = (food['carbs'] is int)
              ? food['carbs']
              : (food['carbs'] as num).toInt();

          final fFat = (f['fat'] is int) ? f['fat'] : (f['fat'] as num).toInt();
          final foodFat =
              (food['fat'] is int) ? food['fat'] : (food['fat'] as num).toInt();

          // Compare loggedTime by converting both to DateTime and comparing timestamps
          final fTime = (f['loggedTime'] as Timestamp).toDate();
          final foodTime = (food['loggedTime'] as Timestamp).toDate();

          return f['mealName'] == food['mealName'] &&
              fCalories == foodCalories &&
              fProtein == foodProtein &&
              fCarbs == foodCarbs &&
              fFat == foodFat &&
              fTime.millisecondsSinceEpoch == foodTime.millisecondsSinceEpoch;
        });

        if (index != -1) {
          // Get the food item being deleted
          final deletedFood = foods[index];

          // Update totals by subtracting the deleted food's values
          foodLogData['totalCalories'] = (foodLogData['totalCalories'] ?? 0) -
              (deletedFood['calories'] ?? 0);
          foodLogData['totalProtein'] = (foodLogData['totalProtein'] ?? 0) -
              (deletedFood['protein'] ?? 0);
          foodLogData['totalCarbs'] =
              (foodLogData['totalCarbs'] ?? 0) - (deletedFood['carbs'] ?? 0);
          foodLogData['totalFat'] =
              (foodLogData['totalFat'] ?? 0) - (deletedFood['fat'] ?? 0);

          // Remove the food item
          foods.removeAt(index);
          foodLogData['foods'] = foods;

          // Save updated food log data
          await FirebaseFirestore.instance
              .collection('food_logs')
              .doc(foodLogId)
              .set(foodLogData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Meal deleted successfully')),
          );

          // Refresh the data
          refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Meal not found')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting meal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting meal: $e')),
      );
    }
  }
}
