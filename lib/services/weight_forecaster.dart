import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeightForecaster {
  final String userId;
  WeightForecaster(this.userId);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if we have enough data for a personalized forecast
  Future<bool> get hasEnoughDataForPersonalizedForecast async {
    try {
      debugPrint(
          "🔍 Checking if user $userId has enough data for personalized forecast...");

      // Get last 14 days of weight entries
      final weightSnapshot = await _firestore
          .collection('weight_history')
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(days: 14))))
          .orderBy('date')
          .get();

      debugPrint("📊 Weight logs found: ${weightSnapshot.docs.length}");

      // Get last 14 days of food logs
      final foodLogSnapshot = await _firestore
          .collection('food_logs')
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(days: 14))))
          .orderBy('date')
          .get();

      debugPrint("🍽️ Food logs found: ${foodLogSnapshot.docs.length}");

      final hasEnoughData =
          weightSnapshot.docs.isNotEmpty && foodLogSnapshot.docs.length >= 14;

      debugPrint("✅ Has enough data for personalized forecast: $hasEnoughData");
      debugPrint(
          "   - Weight logs requirement: ${weightSnapshot.docs.length >= 7 ? 'MET' : 'NOT MET'} (${weightSnapshot.docs.length}/7)");
      debugPrint(
          "   - Food logs requirement: ${foodLogSnapshot.docs.length >= 7 ? 'MET' : 'NOT MET'} (${foodLogSnapshot.docs.length}/7)");

      return hasEnoughData;
    } catch (e) {
      debugPrint("❌ Error checking data for personalized forecast: $e");
      return false;
    }
  }

  // Fetch and calculate average calorie intake for a given number of days
  Future<double> _fetchAverageCalorieIntake(int days) async {
    try {
      debugPrint("🥗 Fetching average calorie intake for last $days days...");

      final snapshot = await _firestore
          .collection('food_logs')
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now().subtract(Duration(days: days))))
          .get();

      debugPrint("📋 Found ${snapshot.docs.length} food log entries");

      if (snapshot.docs.isEmpty) {
        debugPrint("⚠️ No food logs found, returning 0.0");
        return 0.0;
      }

      final totalCalories = snapshot.docs.fold<double>(
          0.0,
          (sum, doc) =>
              sum + ((doc.data()['totalCalories'] as num?)?.toDouble() ?? 0.0));

      // Calculate average based on unique days with data
      Set<String> uniqueDates = snapshot.docs
          .map((doc) => DateFormat('yyyy-MM-dd')
              .format((doc.data()['date'] as Timestamp).toDate()))
          .toSet();

      debugPrint("📅 Unique days with food data: ${uniqueDates.length}");
      debugPrint("🔥 Total calories: $totalCalories");

      final averageCalories = totalCalories / uniqueDates.length;
      debugPrint(
          "📊 Average daily calorie intake: ${averageCalories.toStringAsFixed(1)}");

      return averageCalories;
    } catch (e) {
      debugPrint("❌ Error fetching average calorie intake: $e");
      return 0.0;
    }
  }

  // Calculate BMR (Basal Metabolic Rate) using the Mifflin-St Jeor equation
  double _calculateBMR(
      double weightKg, double heightCm, int age, String gender) {
    debugPrint("🧮 Calculating BMR...");
    debugPrint("   - Weight: ${weightKg}kg");
    debugPrint("   - Height: ${heightCm}cm");
    debugPrint("   - Age: $age");
    debugPrint("   - Gender: $gender");

    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    debugPrint("✅ BMR calculated: ${bmr.toStringAsFixed(1)} kcal");
    return bmr;
  }

  // Calculate TDEE (Total Daily Energy Expenditure) based on BMR and activity level
  double _calculateTDEE(double bmr, String activityLevel) {
    debugPrint("⚡ Calculating TDEE...");
    debugPrint("   - BMR: ${bmr.toStringAsFixed(1)} kcal");
    debugPrint("   - Activity Level: $activityLevel");

    double activityFactor = 1.2; // Sedentary
    switch (activityLevel) {
      case 'Lightly active':
        activityFactor = 1.375;
        break;
      case 'Moderately active':
        activityFactor = 1.55;
        break;
      case 'Very active':
        activityFactor = 1.725;
        break;
      case 'Extra active':
        activityFactor = 1.9;
        break;
    }

    final tdee = bmr * activityFactor;
    debugPrint(
        "✅ TDEE calculated: ${tdee.toStringAsFixed(1)} kcal (Activity Factor: $activityFactor)");
    return tdee;
  }

  // Main forecasting method
  Future<Map<String, dynamic>> forecastWeight({
    required double currentWeight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required double dailyCalorieGoal,
  }) async {
    debugPrint("🚀 STARTING WEIGHT FORECAST ===============================");
    debugPrint("👤 User ID: $userId");
    debugPrint("📊 Current Weight: ${currentWeight}kg");
    debugPrint("📏 Height: ${height}cm");
    debugPrint("🎂 Age: $age");
    debugPrint("🚻 Gender: $gender");
    debugPrint("🏃 Activity Level: $activityLevel");
    debugPrint("🎯 Daily Calorie Goal: ${dailyCalorieGoal}kcal");

    final personalizedForecast = await hasEnoughDataForPersonalizedForecast;

    double dailyCalorieIntake;
    final bmr = _calculateBMR(currentWeight, height, age, gender);
    final tdee = _calculateTDEE(bmr, activityLevel);
    double dailyWeightChangeKg;

    // Use personalized data if available
    if (personalizedForecast) {
      debugPrint("✅ USING PERSONALIZED FORECAST (based on historical data)");
      dailyCalorieIntake = await _fetchAverageCalorieIntake(7);
    } else {
      debugPrint("⚠️ USING PROVISIONAL FORECAST (not enough historical data)");
      // Use the user's provided daily calorie goal for provisional data
      dailyCalorieIntake = dailyCalorieGoal;
      debugPrint("📋 Using daily calorie goal: ${dailyCalorieIntake}kcal");
    }

    final calorieDeficit = dailyCalorieIntake - tdee;
    dailyWeightChangeKg = calorieDeficit / 7700; // 7700 kcal = 1 kg

    debugPrint("📈 DAILY METRICS:");
    debugPrint("   - TDEE: ${tdee.toStringAsFixed(1)} kcal");
    debugPrint(
        "   - Daily Calorie Intake: ${dailyCalorieIntake.toStringAsFixed(1)} kcal");
    debugPrint(
        "   - Calorie Deficit/Surplus: ${calorieDeficit.toStringAsFixed(1)} kcal");
    debugPrint(
        "   - Daily Weight Change: ${dailyWeightChangeKg.toStringAsFixed(4)} kg/day");
    debugPrint(
        "   - Weekly Weight Change: ${(dailyWeightChangeKg * 7).toStringAsFixed(3)} kg/week");

    // Project weight for the next 4 months (16 weeks)
    List<Map<String, dynamic>> projectedWeight = [];
    double projectedWeightKg = currentWeight;

    debugPrint("🔮 PROJECTING WEIGHT FOR NEXT 4 MONTHS (16 WEEKS):");
    for (int i = 1; i <= 8; i++) {
      // 4 months = 16 weeks, display every 2 weeks
      int weeksPassed = i * 2;
      projectedWeightKg =
          currentWeight + (dailyWeightChangeKg * 7 * weeksPassed);

      projectedWeight.add({
        'week': weeksPassed,
        'weight': double.parse(projectedWeightKg.toStringAsFixed(1)),
      });

      debugPrint(
          "   📅 Week $weeksPassed: ${projectedWeightKg.toStringAsFixed(1)}kg");
    }

    final result = {
      'isProvisionalData': !personalizedForecast,
      'projectedWeight': projectedWeight,
      'averageCalorieIntake':
          double.parse(dailyCalorieIntake.toStringAsFixed(1)),
      'calorieSurplusDeficit': double.parse(calorieDeficit.toStringAsFixed(1)),
      'tdee': double.parse(tdee.toStringAsFixed(1)),
      'dailyWeightChange': double.parse(dailyWeightChangeKg.toStringAsFixed(4)),
    };

    debugPrint("✅ FORECAST COMPLETED SUCCESSFULLY");
    debugPrint("   - Provisional Data: ${result['isProvisionalData']}");
    debugPrint(
        "   - Average Calorie Intake: ${result['averageCalorieIntake']} kcal");
    debugPrint(
        "   - Calorie Deficit/Surplus: ${result['calorieSurplusDeficit']} kcal");
    debugPrint("   - TDEE: ${result['tdee']} kcal");
    debugPrint(
        "   - Daily Weight Change: ${result['dailyWeightChange']} kg/day");
    debugPrint("   - Projected Weight Points: ${projectedWeight.length}");
    debugPrint("🚀 FORECAST COMPLETE ======================================");

    return result;
  }
}
