import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/main_screen_widgets/analytics_screen/bar_graph_container.dart';
import 'package:fitness/widgets/main_screen_widgets/analytics_screen/line_graph_container.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:fitness/services/weight_forecaster.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Current logged-in user
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isForecastingEnabled = false;
  Map<String, dynamic>? forecastData;
  bool isLoadingForecast = false;
  bool isProvisionalData = false;
  List<Map<String, dynamic>> _weightHistory = [];
  List<Map<String, dynamic>> _calorieHistory = [];

  // Future to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
  }

  // Load weight history for progress analysis
  Future<void> _loadWeightHistory() async {
    if (currentUser == null) return;

    try {
      debugPrint("🔍 Loading weight history for user: ${currentUser!.uid}");

      final snapshot = await FirebaseFirestore.instance
          .collection('weight_history')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('date', descending: true)
          .limit(5) // Get latest 5 entries to ensure we have data
          .get();

      debugPrint("✅ Found ${snapshot.docs.length} weight entries");

      final List<Map<String, dynamic>> weights = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        weights.add({
          'date': (data['date'] as Timestamp).toDate(),
          'weight': (data['weight'] as num).toDouble(),
        });
        debugPrint(
            "   📊 Weight: ${data['weight']} on ${(data['date'] as Timestamp).toDate()}");
      }

      setState(() {
        _weightHistory = weights;
      });
    } catch (e) {
      debugPrint("❌ Error loading weight history for analysis: $e");
    }
  }

  // Load calorie history for progress analysis
  Future<void> _loadCalorieHistory() async {
    if (currentUser == null) return;

    try {
      // Get date range: from 8 days ago to yesterday (exclude today)
      final today = DateTime.now();
      final eightDaysAgo = today.subtract(Duration(days: 8));
      final yesterday = today.subtract(Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('food_logs')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(eightDaysAgo))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(yesterday))
          .get();

      final List<Map<String, dynamic>> calories = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        calories.add({
          'date': (data['date'] as Timestamp).toDate(),
          'calories': (data['totalCalories'] as num).toDouble(),
        });
      }

      setState(() {
        _calorieHistory = calories;
      });
    } catch (e) {
      debugPrint("Error loading calorie history for analysis: $e");
    }
  }

  // Generate progress review based on user data
  String _getProgressReview(Map<String, dynamic> userData) {
    final calorieGoal = (userData['dailyCalories'] ?? 2000).toDouble();
    final goalWeight =
        double.tryParse(userData['goalWeight']?.toString() ?? '0') ?? 0.0;
    final currentWeight = userData['weight']?.toDouble() ?? 0.0;
    final userGoal = userData['goal'] ?? "maintain";

    debugPrint("📊 Analysis data:");
    debugPrint("   - Calorie goal: $calorieGoal");
    debugPrint("   - Goal weight: $goalWeight");
    debugPrint("   - Current weight: $currentWeight");
    debugPrint("   - User goal: $userGoal");
    debugPrint("   - Weight history entries: ${_weightHistory.length}");
    debugPrint("   - Calorie history entries: ${_calorieHistory.length}");

    // Calculate average daily calories from last 7 days
    double averageCalories = 0;
    if (_calorieHistory.isNotEmpty) {
      final totalCalories =
          _calorieHistory.map((e) => e['calories']).reduce((a, b) => a + b);
      averageCalories = totalCalories / _calorieHistory.length;
      debugPrint("   - 7-day average calories: $averageCalories");
    } else {
      averageCalories = calorieGoal; // Use goal if no history
      debugPrint("   - No calorie history, using goal: $averageCalories");
    }

    // Analyze weight progress
    String weightReview = _analyzeWeightProgress(
        currentWeight, goalWeight, userGoal, _weightHistory);

    // Analyze calorie consistency
    String calorieReview = _analyzeCalorieConsistency(
        averageCalories, calorieGoal, _calorieHistory.length);

    debugPrint("   - Calorie review: $calorieReview");
    debugPrint("   - Weight review: $weightReview");

    // Combine both reviews
    return "$calorieReview$weightReview";
  }

  String _analyzeWeightProgress(double currentWeight, double goalWeight,
      String goal, List<Map<String, dynamic>> weightHistory) {
    double effectiveCurrentWeight = currentWeight;
    double? previousWeight;

    // Use latest weight from history if available
    if (weightHistory.isNotEmpty) {
      effectiveCurrentWeight = weightHistory.first['weight'];

      // Get the 2nd most recent weight if available
      if (weightHistory.length >= 2) {
        previousWeight = weightHistory[1]['weight'];
      }

      debugPrint("   - Using weight from history: $effectiveCurrentWeight");
      if (previousWeight != null) {
        debugPrint("   - Previous weight from history: $previousWeight");
      }
    } else {
      debugPrint("   - Using weight from profile: $effectiveCurrentWeight");
    }

    if (goalWeight == 0) {
      return "Set a weight goal to track your progress.";
    }

    if (effectiveCurrentWeight == 0) {
      return "Log your current weight to start tracking progress.";
    }

    // Compare with goal
    final currentDifference = effectiveCurrentWeight - goalWeight;
    final absoluteCurrentDifference = currentDifference.abs();

    // Analyze progress between two most recent weights if available
    String progressAnalysis = "";
    if (previousWeight != null) {
      final weightChange = effectiveCurrentWeight - previousWeight;
      final absoluteWeightChange = weightChange.abs();

      if (goal == "lose") {
        if (weightChange < 0) {
          progressAnalysis =
              " Amazing progress! You've lost ${absoluteWeightChange.toStringAsFixed(1)}kg since your last measurement. This shows your consistency is paying off!";
        } else if (weightChange > 0) {
          progressAnalysis =
              " You've gained ${absoluteWeightChange.toStringAsFixed(1)}kg since your last measurement. Remember that weight fluctuations are normal, but consistent gains might slow your progress toward your goal.";
        } else {
          progressAnalysis =
              " Your weight has remained stable since your last measurement. Sometimes maintaining is a win too!";
        }
      } else if (goal == "gain") {
        if (weightChange > 0) {
          progressAnalysis =
              " Fantastic work! You've gained ${absoluteWeightChange.toStringAsFixed(1)}kg since your last measurement. Your dedication to building mass is showing results!";
        } else if (weightChange < 0) {
          progressAnalysis =
              " You've lost ${absoluteWeightChange.toStringAsFixed(1)}kg since your last measurement. Don't get discouraged - muscle building takes time and consistent effort.";
        } else {
          progressAnalysis =
              " Your weight has remained stable since your last measurement. Stay patient and trust the process!";
        }
      } else if (goal == "maintain") {
        if (absoluteWeightChange < 0.5) {
          progressAnalysis =
              " Excellent maintenance! Your weight is staying right where you want it.";
        } else if (weightChange > 0) {
          progressAnalysis =
              " You've gained ${absoluteWeightChange.toStringAsFixed(1)}kg. Small adjustments now can help you get back to your maintenance range easily.";
        } else {
          progressAnalysis =
              " You've lost ${absoluteWeightChange.toStringAsFixed(1)}kg. A slight course correction will help you maintain your target weight.";
        }
      }
    }

    // Compare current weight with goal
    String goalAnalysis = "";
    if (goal == "lose" && currentDifference > 0) {
      if (absoluteCurrentDifference < 2) {
        goalAnalysis =
            "You're doing incredible work! Just ${absoluteCurrentDifference.toStringAsFixed(1)}kg to go until you reach your weight loss goal.";
      } else {
        goalAnalysis =
            "You're making progress toward your weight loss goal with ${absoluteCurrentDifference.toStringAsFixed(1)}kg to go. Every small step counts!";
      }
    } else if (goal == "gain" && currentDifference < 0) {
      if (absoluteCurrentDifference < 2) {
        goalAnalysis =
            "You're so close to your weight gain goal - only ${absoluteCurrentDifference.toStringAsFixed(1)}kg left! Your consistency is really showing.";
      } else {
        goalAnalysis =
            "You're on your way to gaining ${absoluteCurrentDifference.toStringAsFixed(1)}kg to reach your goal. Keep fueling your body properly!";
      }
    } else if (goal == "maintain") {
      if (absoluteCurrentDifference < 1) {
        goalAnalysis =
            "Perfect maintenance! You're right where you want to be. This level of consistency is what long-term success looks like.";
      } else {
        goalAnalysis =
            "You're ${absoluteCurrentDifference.toStringAsFixed(1)}kg from your maintenance goal. Small, consistent adjustments will get you right back on track.";
      }
    } else {
      goalAnalysis =
          "Congratulations! You've reached your weight goal. Now the real work begins - maintaining this amazing achievement!";
    }

    return goalAnalysis + progressAnalysis;
  }

  String _analyzeCalorieConsistency(
      double averageCalories, double calorieGoal, int dataPoints) {
    if (dataPoints == 0) {
      return "Start logging your food intake for the next 7 days so we can analyze your patterns and help you optimize your nutrition. ";
    }

    final percentageDifference =
        ((averageCalories - calorieGoal) / calorieGoal * 100);
    final absoluteDifference = percentageDifference.abs();

    debugPrint("(ANALYTICS PAGE) PERCENTAGE DIFFERENCE: $percentageDifference");
    debugPrint("(ANALYTICS PAGE) ABSOLUTE DIFFERENCE: $absoluteDifference");

    if (absoluteDifference < 10) {
      return "Outstanding consistency! Your 7-day average (${averageCalories.toInt()} kcal) is perfectly aligned with your goal. This kind of precision is what creates real results. ";
    } else if (absoluteDifference < 25) {
      if (percentageDifference > 0) {
        return "Good effort this week! Your 7-day average (${averageCalories.toInt()} kcal) is ${absoluteDifference.toInt()}% above your goal. If this continues, it might slow your progress, but you're still building great tracking habits. ";
      } else {
        return "You're putting in the work! Your 7-day average (${averageCalories.toInt()} kcal) is ${absoluteDifference.toInt()}% below your goal. While consistency is key, make sure you're not underfueling your body too much. ";
      }
    } else {
      if (percentageDifference > 0) {
        return "Your 7-day average (${averageCalories.toInt()} kcal) is significantly above your goal. Consistent overconsumption can make it challenging to reach your targets, but every week is a new opportunity to refine your approach. ";
      } else {
        return "Your 7-day average (${averageCalories.toInt()} kcal) is well below your goal. While creating a deficit is important, consistently eating too little can slow your metabolism and leave you feeling drained. ";
      }
    }
  }

  // Toggle forecasting
  void toggleForecasting() async {
    final userData = (await getUserDetails()).data();
    if (userData == null) {
      return;
    }

    setState(() {
      isForecastingEnabled = !isForecastingEnabled;
      if (isForecastingEnabled) {
        isLoadingForecast = true;
      } else {
        forecastData = null;
        isProvisionalData = false;
      }
    });

    if (isForecastingEnabled) {
      final forecaster = WeightForecaster(currentUser!.uid);
      final forecast = await forecaster.forecastWeight(
        currentWeight: userData['weight']?.toDouble() ?? 0,
        height: userData['height']?.toDouble() ?? 0,
        age: userData['age'] ?? 0,
        gender: userData['gender'] ?? 'male',
        activityLevel: userData['selectedActivityLevel'] ??
            userData['activityLevel'] ??
            'Sedentary',
        dailyCalorieGoal: userData['dailyCalories']?.toDouble() ?? 2000,
      );

      setState(() {
        forecastData = forecast;
        isProvisionalData = forecast['isProvisionalData'] ?? false;
        isLoadingForecast = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWeightHistory();
    _loadCalorieHistory();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: getUserDetails(),
          builder: (context, snapshot) {
            // Waiting...
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // If there's an error
            if (snapshot.hasError) {
              return Center(
                  child: Text("Error loading profile",
                      style: TextStyle(color: AppColors.primaryText)));
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data();
              double userGoalWeight =
                  double.tryParse(userData?['goalWeight']?.toString() ?? '0') ??
                      0.0;
              String userGoal = userData?['goal'] ?? "null";
              double userHeight = userData?['height']?.toDouble() ?? 0.0;

              final progressReview = _getProgressReview(userData!);

              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Analytics',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Forecast toggle button
                            ElevatedButton.icon(
                              onPressed: () => toggleForecasting(),
                              icon: isForecastingEnabled
                                  ? Icon(Icons.close)
                                  : Icon(Icons.lightbulb_outline),
                              label: Text(
                                isForecastingEnabled
                                    ? 'Hide Forecast'
                                    : 'Show Forecast',
                                style: TextStyle(
                                  color: isForecastingEnabled
                                      ? AppColors.primaryText
                                      : Colors.blue,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isForecastingEnabled
                                    ? Colors.red[800]
                                    : Colors.grey[800],
                                foregroundColor: AppColors.primaryText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Progress Review Section
                        if (progressReview.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildProgressReviewSection(progressReview),
                        ],

                        if (isForecastingEnabled && isProvisionalData)
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'This is provisional data assuming you hit your daily calorie goals consistently. Log more data for personalized forecasts.',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        SizedBox(height: 20),
                        Text(
                          'Calorie Intake',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        BarGraphContainer(
                          calorieGoal:
                              userData?['dailyCalories']?.toDouble() ?? 2000,
                          isForecasting: isForecastingEnabled,
                          forecastData: forecastData,
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Weight Progress',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        LineGraphContainer(
                          goalWeight: userGoalWeight,
                          goal: userGoal,
                          isForecasting: isForecastingEnabled,
                          userHeight: userHeight,
                          forecastData: forecastData,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            //return if no user found
            return Center(child: Text("User not found"));
          }),
    );
  }

  Widget _buildProgressReviewSection(String reviewMessage) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[800]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.green[300]!.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  color: Colors.green[200], size: 20),
              const SizedBox(width: 8),
              Text(
                'Progress Analysis',
                style: TextStyle(
                  color: Colors.green[200],
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
          const SizedBox(height: 8),
          Text(
            'Based on your last 7 days of data',
            style: TextStyle(
              color: Colors.green[200],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
