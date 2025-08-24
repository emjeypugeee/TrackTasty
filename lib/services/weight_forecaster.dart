import 'package:cloud_firestore/cloud_firestore.dart';

class WeightForecaster {
  final String userId;
  WeightForecaster(this.userId);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if we have enough data (e.g., at least 14 days of weight and calorie data)
  Future<bool> get hasEnoughData async {
    final weightSnapshot = await _firestore
        .collection('weight_history')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(14)
        .get();

    final foodLogSnapshot = await _firestore
        .collection('food_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(14)
        .get();

    // We need a good amount of data to start
    return weightSnapshot.docs.length >= 7 && foodLogSnapshot.docs.length >= 7;
  }

  // The core function to generate a forecast
  Future<Map<String, dynamic>> generateForecast() async {
    if (!await hasEnoughData) {
      return {
        'canForecast': false,
        'message':
            'Keep logging! We need more data to generate a reliable forecast.',
      };
    }

    // 1. FETCH HISTORICAL DATA
    //final weightHistory = await _fetchWeightHistory();
    //final calorieHistory = await _fetchCalorieHistory();

    // 2. CALCULATE TRUE TDEE (The Gold Standard)
    // This is a simplified example. A real implementation would be more robust.
    double totalCalorieDeficitOrSurplus = 0;
    int numberOfDataPoints = 0;

    /*for (int i = 1; i < weightHistory.length; i++) {
      final weightChangeLbs =
          weightHistory[i]['weight'] - weightHistory[i - 1]['weight'];
      final avgDailyCalories = calorieHistory[i]['totalCalories'];
      // Estimate TDEE for this period: TDEE = CaloriesIn - (WeightChangeLbs * 3500 / days)
      // Since we're using daily data, days=1
      final estimatedTDEEDuringPeriod =
          avgDailyCalories - (weightChangeLbs * 3500);
      totalCalorieDeficitOrSurplus += estimatedTDEEDuringPeriod;
      numberOfDataPoints++;
    }*/

    double trueTDEE = totalCalorieDeficitOrSurplus / numberOfDataPoints;

    // 3. GET USER'S GOAL FROM FIRESTORE
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final goal = userDoc['goal']; // e.g., "Lose Weight", "Maintain Weight"
    final double goalCalorieIntake =
        _calculateGoalCalorieIntake(goal, trueTDEE);

    // 4. GENERATE FORECAST (e.g., next 7 days)
    List<Map<String, dynamic>> forecastData = [];
    // double projectedWeight = weightHistory.last['weight'];

    for (int day = 1; day <= 7; day++) {
      // Simple model: (Goal Calories - TDEE) / 3500 = projected daily weight change
      double dailyWeightChange = (goalCalorieIntake - trueTDEE) / 3500;
      // projectedWeight += dailyWeightChange;

      forecastData.add({
        'day': day,
        // 'projectedWeight': double.parse(projectedWeight.toStringAsFixed(1)),
        'targetCalories': goalCalorieIntake.round(),
      });
    }

    // 5. UPDATE THE USER'S TDEE IN FIRESTORE FOR FUTURE USE
    await _firestore.collection('users').doc(userId).update({'tdee': trueTDEE});

    return {
      'canForecast': true,
      'currentTdee': trueTDEE.round(),
      'forecast': forecastData,
    };
  }

  // Helper function to calculate target calories based on goal
  double _calculateGoalCalorieIntake(String goal, double tdee) {
    switch (goal) {
      case 'Lose Weight':
        return tdee - 500; // Create a 500 calorie deficit
      case 'Gain Weight':
        return tdee + 500; // Create a 500 calorie surplus
      case 'Maintain Weight':
      default:
        return tdee;
    }
  }

  /* TEMPORARY FORECAST OF DATA BASED ON GENERATED INFORMATION FOR NEW USERS
  Future<Map<String, dynamic>> generateProvisionalForecast() async {
    // 1. Get user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentWeight = userDoc['weight'];
    final goal = userDoc['goal'];
    final goalCalories =
        userDoc['dailyCalories']; // This was set during onboarding
    final activityLevel = userDoc['selectedActivityLevel'];

    // 2. Calculate Estimated TDEE (using Mifflin-St Jeor for BMR)
    double estimatedBMR = _calculateMifflinStJeor(userDoc['weight'],
        userDoc['height'], userDoc['age'], userDoc['gender']);
    double activityMultiplier = _getActivityMultiplier(activityLevel);
    double estimatedTDEE = estimatedBMR * activityMultiplier;

    // 3. Calculate the projected change based on their GOAL calories, not their intake.
    double dailyCalorieDifference = goalCalories - estimatedTDEE;
    double projectedDailyWeightChange =
        dailyCalorieDifference / 7700; // kcal per kg

    // 4. Generate the forecast for the next 30 days
    List<Map<String, dynamic>> forecastData = [];
    double projectedWeight = currentWeight;

    for (int day = 1; day <= 30; day++) {
      projectedWeight += projectedDailyWeightChange;
      forecastData.add({
        'day': day,
        'projectedWeight': double.parse(projectedWeight.toStringAsFixed(1)),
        'isProvisional': true, // Flag to show this is an estimate
      });
    }

    return {
      'canForecast': true,
      'isProvisional': true, // Key flag for the UI to differentiate
      'message':
          'This forecast assumes you hit your daily calorie goal of ${goalCalories.round()} kcal. Log consistently for a personalized forecast based on your actual data.',
      'currentEstimatedTdee': estimatedTDEE.round(),
      'forecast': forecastData,
    };
  }*/

  /* FORECASTING FOR USERS THAT HAVE ENOUGH INFORMATION (14 FOOD LOGS) + (3 WEEKS OF WEIGHT HISTORY)
  Future<bool> get hasEnoughDataForPersonalizedForecast async {
    // Get last 21 days of weight entries
    final weightSnapshot = await _firestore
        .collection('weight_history')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(21) // 3 weeks
        .get();

    // Get last 14 days of food logs
    final foodLogSnapshot = await _firestore
        .collection('food_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(14)
        .get();

    // Check if we have enough data points and that the data spans a sufficient time period
    // We need at least, e.g., 5 weight logs and 10 food logs that span over 2 weeks.
    return weightSnapshot.docs.length >= 5 && foodLogSnapshot.docs.length >= 10;
  }*/

  /* GET FORECAST EITHER PROVISIONAL OR PERSONALIZED
  Future<Map<String, dynamic>> getForecast() async {
    // First, check if we can do a personalized forecast
    if (await hasEnoughDataForPersonalizedForecast) {
      return await generatePersonalizedForecast(); // This is the function from the previous answer
    } else {
      // If not, provide the provisional one
      return await generateProvisionalForecast();
    }
  }*/

  /* Helper functions to fetch data
  Future<List<Map<String, dynamic>>> _fetchWeightHistory() async {
    // ... implementation to get weight history as a list of maps
  }
  Future<List<Map<String, dynamic>>> _fetchCalorieHistory() async {
    // ... implementation to get daily total calories as a list of maps
  }*/
}
