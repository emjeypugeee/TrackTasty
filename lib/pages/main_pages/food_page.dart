import 'dart:ffi';

import 'package:fitness/services/fat_secret_api_service.dart';
import 'package:fitness/utils/achievement_utils.dart';
import 'package:flutter/material.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/food_page_screen/meal_container.dart';
import 'package:fitness/widgets/main_screen_widgets/home_screen/food_input_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  final FatSecretApiService _apiService = FatSecretApiService();

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _apiService.searchFood(query);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to parse nutrients from food description
  Map<String, dynamic> _parseNutrients(String description) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    String perValue = "1 serving";

    try {
      // Extract serving size (e.g., "1 packet" or "2 brownies")
      if (description.contains("Per ")) {
        final perPart = description.split("Per ")[1].split(" - ")[0].trim();
        perValue = perPart;
      }

      // Extract and parse each nutrient
      if (description.contains("Calories:")) {
        final caloriesPart =
            description.split("Calories:")[1].split("|")[0].trim();
        calories =
            double.tryParse(caloriesPart.replaceAll("kcal", "").trim()) ?? 0;
      }

      if (description.contains("Fat:")) {
        final fatPart = description.split("Fat:")[1].split("|")[0].trim();
        fat = double.tryParse(fatPart.replaceAll("g", "").trim()) ?? 0;
      }

      if (description.contains("Carbs:")) {
        final carbsPart = description.split("Carbs:")[1].split("|")[0].trim();
        carbs = double.tryParse(carbsPart.replaceAll("g", "").trim()) ?? 0;
      }

      if (description.contains("Protein:")) {
        final proteinPart =
            description.split("Protein:")[1].split("|")[0].trim();
        protein = double.tryParse(proteinPart.replaceAll("g", "").trim()) ?? 0;
      }
    } catch (e) {
      debugPrint("Error parsing nutrients: $e");
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'serving': perValue,
    };
  }

  // Function to show food confirmation sheet
  Future<void> _saveFoodToFirebase(
      Map<String, dynamic> food, Map<String, dynamic> nutrients) async {
    final user = FirebaseAuth.instance.currentUser;
    final today = DateTime.now();
    final foodLogId = '${user?.uid}_${today.year}-${today.month}-${today.day}';

    if (user != null) {
      final foodLogDoc = await FirebaseFirestore.instance
          .collection('food_logs')
          .doc(foodLogId)
          .get();

      Map<String, dynamic> foodLogData = {
        'userId': user.uid,
        'date': Timestamp.fromDate(today),
        'totalCalories': 0.0,
        'totalCarbs': 0.0,
        'totalProtein': 0.0,
        'totalFat': 0.0,
        'foods': [],
      };

      // If the document exists, update the data
      if (foodLogDoc.exists && foodLogDoc.data() != null) {
        foodLogData = foodLogDoc.data() as Map<String, dynamic>;

        // Ensure all fields have default values if they're null
        foodLogData['totalCalories'] ??= 0.0;
        foodLogData['totalCarbs'] ??= 0.0;
        foodLogData['totalProtein'] ??= 0.0;
        foodLogData['totalFat'] ??= 0.0;
        foodLogData['foods'] ??= [];
      }

      // Update total macros
      final calories = nutrients['calories'] ?? 0.0;
      final carbs = nutrients['carbs'] ?? 0.0;
      final protein = nutrients['protein'] ?? 0.0;
      final fat = nutrients['fat'] ?? 0.0;

      foodLogData['totalCalories'] =
          (foodLogData['totalCalories'] as double) + calories;
      foodLogData['totalCarbs'] = (foodLogData['totalCarbs'] as double) + carbs;
      foodLogData['totalProtein'] =
          (foodLogData['totalProtein'] as double) + protein;
      foodLogData['totalFat'] = (foodLogData['totalFat'] as double) + fat;

      foodLogData['foods'].add({
        'mealName': food['food_name'],
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fat': fat,
        'loggedTime': Timestamp.fromDate(DateTime.now()),
        'servingSize': nutrients['serving'],
      });

      try {
        await FirebaseFirestore.instance
            .collection('food_logs')
            .doc(foodLogId)
            .set(foodLogData);

        await AchievementUtils.updateAchievementsOnFoodLog(
            userId: user.uid,
            foodLogData: foodLogData,
            newMealName: food['food_name'] ?? '',
            isImageLog: false,
            context: context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${food['food_name']} saved successfully!'),
          ),
        );
        Navigator.pop(context); // Close food page and return to home
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving food: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Food', style: TextStyle(color: AppColors.primaryText)),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for foods...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryText),
                suffixIcon: _isLoading
                    ? CircularProgressIndicator(color: AppColors.primaryText)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primaryText),
                ),
              ),
              onChanged: _searchFood,
              style: TextStyle(color: AppColors.primaryText),
            ),
            SizedBox(height: 30),
            if (_searchResults.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Search for foods to get started',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final food = _searchResults[index];
                    String description = food['food_description'] ?? '';

                    // Parse nutrients from description
                    final nutrients = _parseNutrients(description);

                    return MealContainer(
                      foodName: food['food_name'],
                      foodDescription: description,
                      calories: nutrients['calories'],
                      protein: nutrients['protein'],
                      carbs: nutrients['carbs'],
                      fat: nutrients['fat'],
                      serving: nutrients['serving'],
                      onPressed: () {
                        _saveFoodToFirebase(food, nutrients);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
