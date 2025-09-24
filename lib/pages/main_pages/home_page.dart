import 'dart:async';

import 'package:fitness/provider/user_provider.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<UserProvider>(context, listen: true);
    _loadNutritionData();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    selectedIndex = 6;
    selectedDay = days[selectedIndex];
    _loadNutritionData();
  }

  Future<void> _loadNutritionData() async {
    final user = FirebaseAuth.instance.currentUser;

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
            'hasFoodLogged': true,
          };
        });
      } else {
        setState(() {
          _nutritionData = {
            'totalCalories': 0,
            'totalProtein': 0,
            'totalCarbs': 0,
            'totalFat': 0,
            'hasFoodLogged': false,
          };
        });
      }
    });
  }

  @override
  void dispose() {
    _foodLogSubscription?.cancel();
    super.dispose();
  }

  // Progress review messages
  String _getProgressReview(
      Map<String, dynamic> userData, Map<String, dynamic> nutritionData) {
    final now = DateTime.now();
    final selectedDate =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final today = DateTime(now.year, now.month, now.day);

    // Don't show review for today or future dates
    if (selectedDate.isAfter(today) || selectedDate.isAtSameMomentAs(today)) {
      return '';
    }

    final hasFoodLogged = nutritionData['hasFoodLogged'] ?? false;
    final userAllergies = List<String>.from(userData['allergies'] ?? []);

    // Check if no food was logged for this day
    if (!hasFoodLogged) {
      final noFoodMessages = [
        "No meals were logged for this day. Consistent tracking helps you understand your eating patterns and make better nutritional choices.",
        "You didn't log any food on this day. Remember that tracking your meals is the first step toward achieving your health goals!",
        "It looks like you took a break from tracking on this day. Even on rest days, logging helps maintain awareness of your nutrition habits."
      ];
      return noFoodMessages[
          DateTime.now().millisecondsSinceEpoch % noFoodMessages.length];
    }

    final calorieGoal = (userData['dailyCalories'] ?? 2000).toDouble();
    final proteinGoal = (userData['proteinGram'] ?? 100).toDouble();
    final carbsGoal = (userData['carbsGram'] ?? 250).toDouble();
    final fatGoal = (userData['fatsGram'] ?? 70).toDouble();

    final totalCalories = (nutritionData['totalCalories'] ?? 0).toDouble();
    final totalProtein = (nutritionData['totalProtein'] ?? 0).toDouble();
    final totalCarbs = (nutritionData['totalCarbs'] ?? 0).toDouble();
    final totalFat = (nutritionData['totalFat'] ?? 0).toDouble();

    // Define thresholds (20% deviation from goal)
    final lowThreshold = 0.8;
    final highThreshold = 1.2;

    // Check each macro and generate appropriate messages
    final List<String> issues = [];

    // Calories check
    if (totalCalories < calorieGoal * lowThreshold) {
      issues.add('low_calories');
    } else if (totalCalories > calorieGoal * highThreshold) {
      issues.add('high_calories');
    }

    // Protein check
    if (totalProtein < proteinGoal * lowThreshold) {
      issues.add('low_protein');
    } else if (totalProtein > proteinGoal * highThreshold) {
      issues.add('high_protein');
    }

    // Carbs check
    if (totalCarbs < carbsGoal * lowThreshold) {
      issues.add('low_carbs');
    } else if (totalCarbs > carbsGoal * highThreshold) {
      issues.add('high_carbs');
    }

    // Fat check
    if (totalFat < fatGoal * lowThreshold) {
      issues.add('low_fat');
    } else if (totalFat > fatGoal * highThreshold) {
      issues.add('high_fat');
    }

    // If no significant issues, provide positive feedback
    if (issues.isEmpty) {
      final balancedMessages = [
        "Great job! Your nutrition was well-balanced on this day. Keep up the good work!",
        "Excellent balance! Your macros were perfectly aligned with your goals.",
        "Perfect nutrition day! You hit all your targets just right.",
        "Well done! Your meal planning was spot on for this day."
      ];
      return balancedMessages[
          DateTime.now().millisecondsSinceEpoch % balancedMessages.length];
    }

    // Select one random issue to focus on
    final randomIssue =
        issues[DateTime.now().millisecondsSinceEpoch % issues.length];

    return _getMessageForIssue(
        randomIssue,
        calorieGoal,
        proteinGoal,
        carbsGoal,
        fatGoal,
        totalCalories,
        totalProtein,
        totalCarbs,
        totalFat,
        userAllergies);
  }

  String _getMessageForIssue(
      String issue,
      double calorieGoal,
      double proteinGoal,
      double carbsGoal,
      double fatGoal,
      double totalCalories,
      double totalProtein,
      double totalCarbs,
      double totalFat,
      List<String> userAllergies) {
    // Helper function to filter meal suggestions based on allergies
    List<String> getAllergySafeSuggestions(
        List<String> suggestions, List<String> allergies) {
      final allergyKeywords = {
        'Crustacean Shellfish': [
          'shrimp',
          'crab',
          'lobster',
          'crawfish',
          'shellfish'
        ],
        'Dairy (Milk)': [
          'milk',
          'cheese',
          'butter',
          'yogurt',
          'dairy',
          'greek yogurt',
          'cottage cheese'
        ],
        'Egg': ['egg', 'eggs', 'mayonnaise', 'custard'],
        'Fish': ['fish', 'tuna', 'salmon', 'cod', 'trout', 'seafood'],
        'Peanut': ['peanut', 'peanuts', 'peanut butter'],
        'Sesame': ['sesame', 'tahini', 'sesame seed'],
        'Soy': ['soy', 'tofu', 'edamame', 'soy sauce', 'soybean'],
        'Tree Nuts': [
          'almond',
          'walnut',
          'cashew',
          'pecan',
          'nut',
          'nuts',
          'nut butter'
        ],
        'Wheat': [
          'wheat',
          'bread',
          'pasta',
          'flour',
          'cereal',
          'whole grain',
          'oatmeal'
        ]
      };

      return suggestions.where((suggestion) {
        final lowerSuggestion = suggestion.toLowerCase();
        for (final allergy in allergies) {
          final keywords = allergyKeywords[allergy] ?? [];
          for (final keyword in keywords) {
            if (lowerSuggestion.contains(keyword)) {
              return false; // Exclude if contains allergen
            }
          }
        }
        return true; // Include if no allergens found
      }).toList();
    }

    // Get safe suggestions or fallback messages
    List<String> getSafeSuggestions(List<String> suggestions) {
      final safeSuggestions =
          getAllergySafeSuggestions(suggestions, userAllergies);
      if (safeSuggestions.isEmpty) {
        return [
          'Try incorporating foods that align with your dietary restrictions and preferences.'
        ];
      }
      return safeSuggestions;
    }

    switch (issue) {
      case 'low_calories':
        final calorieSuggestions = [
          "Greek yogurt with berries",
          "handful of nuts",
          "avocado toast",
          "smoothie with banana and peanut butter",
          "oatmeal with fruits",
          "sweet potatoes",
          "rice cakes with almond butter",
          "protein shake"
        ];
        final safeSuggestions = getSafeSuggestions(calorieSuggestions);
        final lowCalorieMessages = [
          "You consumed ${(calorieGoal - totalCalories).toInt()} fewer calories than your goal. Consider adding a nutrient-dense snack like ${safeSuggestions[0]} to meet your energy needs.",
          "Your calorie intake was a bit low. Try incorporating energy-boosting foods like ${safeSuggestions[0]} to reach your daily target.",
          "You're under your calorie goal. Adding complex carbs like ${safeSuggestions[0]} can help you meet your energy requirements sustainably."
        ];
        return lowCalorieMessages[
            DateTime.now().millisecondsSinceEpoch % lowCalorieMessages.length];

      case 'high_calories':
        final highCalorieMessages = [
          "You exceeded your calorie goal by ${(totalCalories - calorieGoal).toInt()} calories. For better weight management, try smaller portions or choose lower-calorie alternatives like vegetables and lean proteins.",
          "Calorie intake was higher than planned. Focus on portion control and include more fiber-rich foods to feel full with fewer calories.",
          "You consumed more calories than needed. Consider balancing with lighter meals the next day and increasing physical activity."
        ];
        return highCalorieMessages[
            DateTime.now().millisecondsSinceEpoch % highCalorieMessages.length];

      case 'low_protein':
        final proteinSuggestions = [
          "chicken breast",
          "eggs",
          "lentils",
          "Greek yogurt",
          "tofu",
          "fish",
          "cottage cheese",
          "protein shakes",
          "lean beef"
        ];
        final safeSuggestions = getSafeSuggestions(proteinSuggestions);
        final lowProteinMessages = [
          "Protein intake was ${(proteinGoal - totalProtein).toInt()}g below target. Protein is essential for muscle repair. Try adding ${safeSuggestions[0]} to your meals.",
          "You need more protein for optimal health. Consider ${safeSuggestions[0]} to support muscle maintenance and satiety.",
          "Low protein detected. Incorporate protein-rich snacks like ${safeSuggestions[0]} to meet your daily requirements."
        ];
        return lowProteinMessages[
            DateTime.now().millisecondsSinceEpoch % lowProteinMessages.length];

      case 'high_protein':
        final highProteinMessages = [
          "Protein consumption was ${(totalProtein - proteinGoal).toInt()}g above goal. While protein is important, excess can strain kidneys. Balance with more vegetables and carbs.",
          "You exceeded your protein target. Consider diversifying with more complex carbohydrates and healthy fats for balanced nutrition.",
          "High protein intake noted. Ensure you're drinking plenty of water and include fiber-rich foods to support digestion."
        ];
        return highProteinMessages[
            DateTime.now().millisecondsSinceEpoch % highProteinMessages.length];

      case 'low_carbs':
        final carbSuggestions = [
          "brown rice",
          "quinoa",
          "bananas",
          "whole grains",
          "fruits",
          "starchy vegetables",
          "oatmeal",
          "whole wheat bread",
          "sweet potatoes"
        ];
        final safeSuggestions = getSafeSuggestions(carbSuggestions);
        final lowCarbMessages = [
          "Carbohydrates were ${(carbsGoal - totalCarbs).toInt()}g below your goal. Carbs provide energy for daily activities. Try adding ${safeSuggestions[0]} to your meals.",
          "Low carb intake can lead to fatigue. Include energy sources like ${safeSuggestions[0]} to maintain optimal energy levels.",
          "You need more carbohydrates for fuel. Consider ${safeSuggestions[0]} to support your activity needs."
        ];
        return lowCarbMessages[
            DateTime.now().millisecondsSinceEpoch % lowCarbMessages.length];

      case 'high_carbs':
        final highCarbMessages = [
          "Carb intake exceeded by ${(totalCarbs - carbsGoal).toInt()}g. Focus on complex carbs like whole grains instead of refined carbs, and balance with protein and fats.",
          "High carbohydrate consumption detected. Choose fiber-rich options and pair with protein to stabilize blood sugar levels.",
          "You consumed more carbs than needed. Consider reducing portion sizes and focusing on quality sources like vegetables and legumes."
        ];
        return highCarbMessages[
            DateTime.now().millisecondsSinceEpoch % highCarbMessages.length];

      case 'low_fat':
        final fatSuggestions = [
          "avocado",
          "nuts",
          "olive oil",
          "salmon",
          "chia seeds",
          "nut butter",
          "eggs",
          "dark chocolate",
          "coconut oil"
        ];
        final safeSuggestions = getSafeSuggestions(fatSuggestions);
        final lowFatMessages = [
          "Fat intake was ${(fatGoal - totalFat).toInt()}g below target. Healthy fats support hormone production. Add ${safeSuggestions[0]} to your meals.",
          "You need more healthy fats for brain health and vitamin absorption. Try incorporating ${safeSuggestions[0]} into your diet.",
          "Low fat detected. Include sources like ${safeSuggestions[0]} to support overall health and satiety."
        ];
        return lowFatMessages[
            DateTime.now().millisecondsSinceEpoch % lowFatMessages.length];

      case 'high_fat':
        final highFatMessages = [
          "Fat consumption exceeded by ${(totalFat - fatGoal).toInt()}g. While fats are essential, excess can lead to weight gain. Choose lean proteins and increase vegetable intake.",
          "High fat intake noted. Focus on unsaturated fats like those in fish and nuts, and reduce saturated fats for heart health.",
          "You consumed more fat than planned. Balance with high-fiber foods and consider grilling or baking instead of frying."
        ];
        return highFatMessages[
            DateTime.now().millisecondsSinceEpoch % highFatMessages.length];

      default:
        return "Keep tracking your nutrition! Consistency is key to reaching your health goals.";
    }
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
              const SizedBox(height: 20),
              _buildNutritionProgressSection(),

              // Progress Review Section
              const SizedBox(height: 20),
              _buildProgressReviewSection(),

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

  Widget _buildProgressReviewSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseAuth.instance.currentUser?.email)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError ||
            !userSnapshot.hasData ||
            !userSnapshot.data!.exists) {
          return const SizedBox(); // Hide if no user data
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // Hide while loading
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final reviewMessage =
            _getProgressReview(userData, _nutritionData ?? {});

        // Don't show anything if no message or for today's date
        if (reviewMessage.isEmpty) {
          return const SizedBox();
        }

        // Determine bubble color based on message type
        Color bubbleColor;
        Color borderColor;
        Color iconColor;

        if (reviewMessage.contains("No meals were logged") ||
            reviewMessage.contains("didn't log any food") ||
            reviewMessage.contains("took a break from tracking")) {
          // Yellow/orange for reminder messages
          bubbleColor = Colors.orange[800]!.withOpacity(0.3);
          borderColor = Colors.orange[300]!.withOpacity(0.5);
          iconColor = Colors.orange[200]!;
        } else if (reviewMessage.contains("Great job") ||
            reviewMessage.contains("Excellent balance") ||
            reviewMessage.contains("Perfect nutrition") ||
            reviewMessage.contains("Well done")) {
          // Green for positive messages
          bubbleColor = Colors.green[800]!.withOpacity(0.3);
          borderColor = Colors.green[300]!.withOpacity(0.5);
          iconColor = Colors.green[200]!;
        } else {
          // Blue for regular feedback messages
          bubbleColor = Colors.blue[800]!.withOpacity(0.3);
          borderColor = Colors.blue[300]!.withOpacity(0.5);
          iconColor = Colors.blue[200]!;
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Nutrition Review',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reviewMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
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
        // Handle connection errors with retry functionality
        if (userSnapshot.hasError) {
          // Check if it's a network error
          final error = userSnapshot.error;
          if (error is FirebaseException &&
              (error.code == 'unavailable' || error.code == 'network-error')) {
            // Retry after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                _loadNutritionData(); // Retry loading data
              }
            });

            return Column(
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 40,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 10),
                Text(
                  'Connection issue\nRetrying in 3 seconds...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            );
          }

          // For other errors, show error message
          return Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red[300],
              ),
              const SizedBox(height: 10),
              Text(
                'Error fetching user data.',
                style: TextStyle(color: Colors.red[300]),
              ),
            ],
          );
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Text(
            'Error fetching user data.',
            style: TextStyle(color: Colors.red),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final calorieGoal = (userData['dailyCalories'] ?? 2000).toInt();
        final proteinGoal = (userData['proteinGram'] ?? 100).toInt();
        final carbsGoal = (userData['carbsGram'] ?? 250).toInt();
        final fatGoal = (userData['fatsGram'] ?? 70).toInt();

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
            // Handle connection errors with retry functionality
            if (snapshot.hasError) {
              // Check if it's a network error
              final error = snapshot.error;
              if (error is FirebaseException &&
                  (error.code == 'unavailable' ||
                      error.code == 'network-error')) {
                // Retry after 3 seconds
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    _loadNutritionData(); // Retry loading data
                  }
                });

                return Column(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Connection issue\nRetrying in 3 seconds...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }

              // For other errors, show error message
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Rest of the existing code remains the same...
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

            // Sort the foods list from latest to oldest logged time
            foods.sort((a, b) {
              final aTime = (a['loggedTime'] as Timestamp).toDate();
              final bTime = (b['loggedTime'] as Timestamp).toDate();
              return bTime.compareTo(aTime); // b before a for latest first
            });

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
