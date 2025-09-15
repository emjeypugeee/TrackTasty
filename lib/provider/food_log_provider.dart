import 'package:fitness/model/food_item.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodLogProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add food to log
  Future<void> addFoodToLog(FoodItem food) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final foodLogId = '${user.uid}_${today.year}-${today.month}-${today.day}';

        // Fetch existing food log for today or create a new one
        final foodLogDoc = await _firestore.collection('food_logs').doc(foodLogId).get();

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
        final calories = food.calories;
        final carbs = food.carbs;
        final protein = food.protein;
        final fat = food.fat;

        foodLogData['totalCalories'] = (foodLogData['totalCalories'] ?? 0) + calories;
        foodLogData['totalCarbs'] = (foodLogData['totalCarbs'] ?? 0) + carbs;
        foodLogData['totalProtein'] = (foodLogData['totalProtein'] ?? 0) + protein;
        foodLogData['totalFat'] = (foodLogData['totalFat'] ?? 0) + fat;

        // Add the new food item
        foodLogData['foods'].add({
          'mealName': food.mealName,
          'calories': calories,
          'carbs': carbs,
          'protein': protein,
          'fat': fat,
          'loggedTime': Timestamp.fromDate(DateTime.now()),
          'servingSize': food.servingSize,
          'mealType': food.mealType,
        });

        // Save updated food log data
        await _firestore.collection('food_logs').doc(foodLogId).set(foodLogData);

        notifyListeners(); // Notify listeners that data has changed
      }
    } catch (e) {
      debugPrint('Error saving food: $e');
      rethrow;
    }
  }

  // Get today's food log
  Future<Map<String, dynamic>?> getTodaysFoodLog() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final foodLogId = '${user.uid}_${today.year}-${today.month}-${today.day}';

        final foodLogDoc = await _firestore.collection('food_logs').doc(foodLogId).get();

        if (foodLogDoc.exists && foodLogDoc.data() != null) {
          return foodLogDoc.data();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting food log: $e');
      rethrow;
    }
  }

  // Get food log for a specific date
  Future<Map<String, dynamic>?> getFoodLogForDate(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final foodLogId = '${user.uid}_${date.year}-${date.month}-${date.day}';

        final foodLogDoc = await _firestore.collection('food_logs').doc(foodLogId).get();

        if (foodLogDoc.exists && foodLogDoc.data() != null) {
          return foodLogDoc.data();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting food log: $e');
      rethrow;
    }
  }

  // Remove food from log
  Future<void> removeFoodFromLog(String foodLogId, int foodIndex) async {
    try {
      final foodLogDoc = await _firestore.collection('food_logs').doc(foodLogId).get();

      if (foodLogDoc.exists && foodLogDoc.data() != null) {
        Map<String, dynamic> foodLogData = foodLogDoc.data() as Map<String, dynamic>;

        // Get the food item to remove
        final foodToRemove = foodLogData['foods'][foodIndex];

        // Update total macros
        foodLogData['totalCalories'] -= foodToRemove['calories'] ?? 0;
        foodLogData['totalCarbs'] -= foodToRemove['carbs'] ?? 0;
        foodLogData['totalProtein'] -= foodToRemove['protein'] ?? 0;
        foodLogData['totalFat'] -= foodToRemove['fat'] ?? 0;

        // Remove the food item
        foodLogData['foods'].removeAt(foodIndex);

        // Save updated food log data
        await _firestore.collection('food_logs').doc(foodLogId).set(foodLogData);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing food: $e');
      rethrow;
    }
  }
}
