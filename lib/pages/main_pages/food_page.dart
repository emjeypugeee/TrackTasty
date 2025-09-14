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
  void _showFoodConfirmationSheet(
      Map<String, dynamic> food, Map<String, dynamic> nutrients) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white, width: 2),
      ),
      builder: (context) {
        return FoodInputSheet(
          initialMealName: food['food_name'],
          initialCalories: nutrients['calories'].toDouble(),
          initialProtein: nutrients['protein'].toDouble(),
          initialCarbs: nutrients['carbs'].toDouble(),
          initialFat: nutrients['fat'].toDouble(),
          initialServingSize: nutrients['serving'],
          onSubmit: (mealData) async {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final today = DateTime.now();
              final foodLogId =
                  '${user.uid}_${today.year}-${today.month}-${today.day}';

              try {
                // Fetch existing food log for today or create a new one
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
                  'mealName': mealData['mealName'] ?? food['food_name'],
                  'calories': calories,
                  'carbs': carbs,
                  'protein': protein,
                  'fat': fat,
                  'servingSize':
                      mealData['servingSize'] ?? nutrients['serving'],
                  'adjustmentType': mealData['adjustmentType'] ?? 'percent',
                  'adjustmentValue': mealData['adjustmentValue'] ?? 100.0,
                  'loggedTime': Timestamp.fromDate(DateTime.now()),
                });

                // Save updated food log data
                await FirebaseFirestore.instance
                    .collection('food_logs')
                    .doc(foodLogId)
                    .set(foodLogData);

                await AchievementUtils.updateAchievementsOnFoodLog(
                    userId: user.uid,
                    foodLogData: foodLogData,
                    newMealName: mealData['mealName'] ?? food['food_name'],
                    isImageLog: false,
                    context: context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('${food['food_name']} added successfully!')),
                );

                Navigator.pop(context);
                Navigator.pop(context);
              } catch (e) {
                debugPrint('Error saving food: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving food: $e')),
                );
              }
            }
          },
        );
      },
    );
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
                      calories: nutrients['calories'].toDouble(),
                      protein: nutrients['protein'].toDouble(),
                      carbs: nutrients['carbs'].toDouble(),
                      fat: nutrients['fat'].toDouble(),
                      serving: nutrients['serving'],
                      onPressed: () {
                        _showFoodConfirmationSheet(food, nutrients);
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
