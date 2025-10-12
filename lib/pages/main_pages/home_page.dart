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
  StreamSubscription<QuerySnapshot>? _foodLogSubscription;

  // Streak data
  int _currentStreak = 0;
  int _highestStreak = 0;
  bool _isLoadingStreak = true;

  void refreshData() {
    _loadNutritionData();
    _loadStreakData();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<UserProvider>(context, listen: true);
    _loadNutritionData();
    _loadStreakData();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    selectedIndex = 6;
    selectedDay = days[selectedIndex];
    _loadNutritionData();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentStreak = (userData['daily_streak'] ?? 0).toInt();
          _highestStreak = (userData['highest_streak'] ?? 0).toInt();
          _isLoadingStreak = false;
        });
      } else {
        setState(() {
          _isLoadingStreak = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading streak data: $e');
      setState(() {
        _isLoadingStreak = false;
      });
    }
  }

  Future<void> _loadNutritionData() async {
    final user = FirebaseAuth.instance.currentUser;

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

    // Don't show review for today
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

    final lowThreshold = 0.8;
    final highThreshold = 1.2;

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
              return false;
            }
          }
        }
        return true;
      }).toList();
    }

    // Get safe suggestions
    List<String> getSafeSuggestions(List<String> suggestions) {
      final safeSuggestions =
          getAllergySafeSuggestions(suggestions, userAllergies);
      if (safeSuggestions.isEmpty) {
        return [
          'Lets explore some foods that work with your dietary preferences. Well find great options together.'
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
          "You're almost there. Just ${(calorieGoal - totalCalories).toInt()} calories shy of your goal. If this continues, you might feel tired and sluggish. Your body needs that energy, so maybe try adding ${safeSuggestions[0]} to power through your day!",
          "I notice your energy intake was a bit light today. Without enough calories, your metabolism could slow down. Think of food as fuel. Adding something like ${safeSuggestions[0]} can help you feel more energized and ready to tackle tomorrow.",
          "Your body's asking for a bit more fuel today. Consistent low intake can lead to nutrient deficiencies. No worries though. We all have lighter days! Consider ${safeSuggestions[0]} to help you finish strong and feel your best."
        ];
        return lowCalorieMessages[
            DateTime.now().millisecondsSinceEpoch % lowCalorieMessages.length];

      case 'high_calories':
        final highCalorieMessages = [
          "You went over by ${(totalCalories - calorieGoal).toInt()} calories today. Regular overconsumption can make it harder to reach your health goals. No big deal. Tomorrow's a fresh start! Maybe try adding an extra vegetable portion to your meals, or take a walk to balance things out.",
          "We all have days when we eat a bit more than planned. If this becomes a pattern, it might slow your progress. Your body is resilient! For tomorrow, focus on listening to your hunger cues. You've got this.",
          "Your calorie intake was a bit higher than target today. Consistent excess can lead to unwanted weight gain. Remember, progress isnt perfect every day. Maybe try starting tomorrow with a protein-rich breakfast to set the tone."
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
          "Your muscles need protein to recover and stay strong. You're just ${(proteinGoal - totalProtein).toInt()}g short. Without enough protein, you might experience muscle loss and slower recovery. Adding ${safeSuggestions[0]} to your next meal can make all the difference!",
          "Protein helps keep you full and supports your body throughout the day. Insufficient protein can lead to weakness and fatigue. Let's aim to include ${safeSuggestions[0]} tomorrow. Your body will thank you!",
          "I notice your protein was a bit low today. Consistent low protein intake can affect your muscle mass and immune function. No worries. Tomorrow's another opportunity! Try starting your day with ${safeSuggestions[0]} to build that strong foundation."
        ];
        return lowProteinMessages[
            DateTime.now().millisecondsSinceEpoch % lowProteinMessages.length];

      case 'high_protein':
        final highProteinMessages = [
          "You're really focused on protein. Thats great! You went ${(totalProtein - proteinGoal).toInt()}g over today. While protein is important, too much can strain your kidneys over time. For optimal balance, lets make sure to include plenty of colorful vegetables and healthy carbs with your meals.",
          "Your dedication to protein is awesome! To help your body process it efficiently, remember that excess protein may lead to digestive issues. Drink plenty of water and include some fiber-rich foods with your meals.",
          "You're nailing the protein intake! For even better results, keep in mind that very high protein diets can sometimes cause dehydration. Lets balance it out tomorrow with some extra veggies and whole grains. Your energy levels will love it."
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
          "Carbs are your body's preferred energy source. You're just ${(carbsGoal - totalCarbs).toInt()}g short. Without enough carbs, you might experience brain fog and low energy. Adding ${safeSuggestions[0]} can help you feel more energized and focused!",
          "I notice your energy fuel was a bit low today. Chronic low carb intake can affect your workout performance and mental clarity. Think of carbs as premium gasoline for your body. ${safeSuggestions[0]} can help you power through your activities with ease.",
          "Your body could use a bit more fuel for optimal performance. Insufficient carbs may lead to fatigue and irritability. Lets try adding ${safeSuggestions[0]} tomorrow. You'll notice the difference in your energy levels!"
        ];
        return lowCarbMessages[
            DateTime.now().millisecondsSinceEpoch % lowCarbMessages.length];

      case 'high_carbs':
        final highCarbMessages = [
          "You had a carb-heavy day. Thats okay! We all crave them sometimes. Regular excess carb intake can lead to blood sugar spikes and weight gain. Tomorrow, lets focus on pairing carbs with protein and healthy fats to keep your energy stable all day.",
          "Carbs are delicious, and I get it! If high carb days become frequent, it might be harder to maintain your target weight. For tomorrow, try choosing fiber-rich options like whole grains and veggies. They'll keep you satisfied longer and support your goals.",
          "Your carb intake was higher than planned today. Consistent overconsumption can affect your metabolic health. No stress! Tomorrow, lets focus on balanced meals. You have the awareness to make great choices."
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
          "Healthy fats are essential for hormone health and vitamin absorption. You're just ${(fatGoal - totalFat).toInt()}g short. Without enough fat, you might experience dry skin and vitamin deficiencies. Adding ${safeSuggestions[0]} can help your body function at its best!",
          "Your body needs healthy fats to thrive. Insufficient fat intake can lead to hormone imbalances and poor nutrient absorption. Lets try incorporating ${safeSuggestions[0]} tomorrow. Its amazing how much better you'll feel with that balance.",
          "I notice your fat intake was a bit light today. Consistently low fat can affect your skin health and energy levels. No problem! Healthy fats from sources like ${safeSuggestions[0]} can actually help you feel more satisfied and energized."
        ];
        return lowFatMessages[
            DateTime.now().millisecondsSinceEpoch % lowFatMessages.length];

      case 'high_fat':
        final highFatMessages = [
          "You had a higher fat day today. It happens! Regular high fat intake can contribute to heart health concerns over time. Your body is amazing at adapting. Tomorrow, lets focus on lean proteins and colorful vegetables to find that perfect balance.",
          "Fats are important, and you're clearly not afraid of them! Too much saturated fat can impact your cholesterol levels. For optimal health, lets aim for more unsaturated fats from fish and nuts tomorrow. Your heart will thank you.",
          "Your fat intake was a bit over today. Consistent excess fat consumption may lead to weight gain and digestive discomfort. No worries. You're building awareness! Tomorrow, try grilling or baking instead of frying, and notice how your body responds."
        ];
        return highFatMessages[
            DateTime.now().millisecondsSinceEpoch % highFatMessages.length];

      default:
        return "Excellent work tracking your nutrition today! Consistency like this is what creates lasting results. Keep up this amazing commitment to your health!";
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
          return const SizedBox();
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final reviewMessage =
            _getProgressReview(userData, _nutritionData ?? {});

        if (reviewMessage.isEmpty) {
          return const SizedBox();
        }

        Color bubbleColor;
        Color borderColor;
        Color iconColor;

        if (reviewMessage.contains("No meals were logged") ||
            reviewMessage.contains("didn't log any food") ||
            reviewMessage.contains("took a break from tracking")) {
          // Yellow/orange for reminder messages
          bubbleColor = Colors.orange[800]!.withValues(alpha: 0.3);
          borderColor = Colors.orange[300]!.withValues(alpha: 0.5);
          iconColor = Colors.orange[200]!;
        } else if (reviewMessage.contains("Great job") ||
            reviewMessage.contains("Excellent balance") ||
            reviewMessage.contains("Perfect nutrition") ||
            reviewMessage.contains("Well done")) {
          // Green for positive messages
          bubbleColor = Colors.green[800]!.withValues(alpha: 0.3);
          borderColor = Colors.green[300]!.withValues(alpha: 0.5);
          iconColor = Colors.green[200]!;
        } else {
          // Blue for regular feedback messages
          bubbleColor = Colors.blue[800]!.withValues(alpha: 0.3);
          borderColor = Colors.blue[300]!.withValues(alpha: 0.5);
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
        if (userSnapshot.hasError) {
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

  bool _isTodaySelected() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    return today == selected;
  }

  Widget _buildStreakDisplay() {
    if (_isLoadingStreak) {
      return const SizedBox();
    }

    if (_currentStreak == 0) {
      return const SizedBox();
    }

    // Determine colors and message based on streak length
    Color backgroundColor;
    Color textColor;
    String encouragement;
    String fireEmojis;

    if (_currentStreak >= 30) {
      backgroundColor = Colors.deepPurple.withValues(alpha: 0.3);
      textColor = Colors.purpleAccent;
      encouragement = "Legendary consistency! You're unstoppable! 🔥";
      fireEmojis = "🔥🔥🔥🔥🔥";
    } else if (_currentStreak >= 14) {
      backgroundColor = Colors.red.withValues(alpha: 0.3);
      textColor = Colors.orangeAccent;
      encouragement = "Amazing dedication! You're building powerful habits!";
      fireEmojis = "🔥🔥🔥🔥";
    } else if (_currentStreak >= 7) {
      backgroundColor = Colors.orange.withValues(alpha: 0.3);
      textColor = Colors.yellowAccent;
      encouragement = "Great work! Your consistency is paying off!";
      fireEmojis = "🔥🔥🔥";
    } else if (_currentStreak >= 3) {
      backgroundColor = Colors.blue.withValues(alpha: 0.3);
      textColor = Colors.cyanAccent;
      encouragement = "Nice streak! Keep going, you're doing great!";
      fireEmojis = "🔥🔥";
    } else {
      backgroundColor = Colors.green.withValues(alpha: 0.3);
      textColor = Colors.lightGreenAccent;
      encouragement = "Good start! Every day counts!";
      fireEmojis = "🔥";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(
            fireEmojis,
            style: const TextStyle(fontSize: 20),
          ),

          // Streak count
          Text(
            '$_currentStreak day${_currentStreak == 1 ? '' : 's'} streak!',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          // Encouragement message
          Text(
            encouragement,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // Highest streak (if applicable and different from current)
          if (_highestStreak > _currentStreak)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Highest streak: $_highestStreak days',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Fire emojis on bottom
          Text(
            fireEmojis,
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
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
              final error = snapshot.error;
              if (error is FirebaseException &&
                  (error.code == 'unavailable' ||
                      error.code == 'network-error')) {
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
