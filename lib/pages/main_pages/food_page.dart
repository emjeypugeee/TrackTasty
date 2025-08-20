// food_page.dart
import 'dart:ffi';

import 'package:fitness/services/fat_secret_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/food_page_screen/meal_container.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  final FatSecretApiService _apiService = FatSecretApiService(); // Add this line

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _apiService.searchFood(query); // Updated line
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ... (keep ALL other methods and UI code EXACTLY the same)
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
                suffixIcon:
                    _isLoading ? CircularProgressIndicator(color: AppColors.primaryText) : null,
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
              Column(
                children: [],
              )
            else
              Expanded(
                  child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final food = _searchResults[index];
                  String description = food['food_description']; // Assume it's a String

                  // Extract Protein using split() or regex
                  String proteinValue = "N/A";
                  String carbsValue = "N/A";
                  String caloriesValue = "N/A";
                  String fatValue = "N/A";
                  String perValue = description.split("Per ")[1].split(" - ")[0].trim();
                  try {
                    List<String> parts = description.split("|");

                    // Safe extraction with orElse for each nutrient
                    proteinValue = parts
                        .firstWhere(
                          (part) => part.trim().startsWith("Protein"),
                          orElse: () => "Protein: N/A",
                        )
                        .split(":")
                        .last
                        .trim();

                    carbsValue = parts
                        .firstWhere(
                          (part) => part.trim().startsWith("Carbs"),
                          orElse: () => "Carbs: N/A",
                        )
                        .split(":")
                        .last
                        .trim();

                    caloriesValue = parts
                        .firstWhere(
                          (part) => part.trim().startsWith("Per"),
                          orElse: () => "Calories: N/A",
                        )
                        .split(":")
                        .last
                        .trim();

                    fatValue = parts
                        .firstWhere(
                          (part) => part.trim().startsWith("Fat"),
                          orElse: () => "Fat: N/A",
                        )
                        .split(":")
                        .last
                        .trim();
                  } catch (e) {
                    print("Error parsing nutrients: $e");
                  }

                  return MealContainer(
                      foodName: food['food_name'],
                      foodDescription: description,
                      onPressed: () {
                        print("Protein: $proteinValue");
                        print("Carbs: $carbsValue");
                        print("Calories: $caloriesValue");
                        print("Fat: $fatValue");
                        print("Serving: $perValue");
                      });
                },
              )),
          ],
        ),
      ),
    );
  }
}
