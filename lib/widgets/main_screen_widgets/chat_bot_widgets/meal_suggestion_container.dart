import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MealSuggestionContainer extends StatefulWidget {
  final Map<String, dynamic> mealData;
  final VoidCallback onAdded;

  const MealSuggestionContainer({
    super.key,
    required this.mealData,
    required this.onAdded,
  });

  @override
  State<MealSuggestionContainer> createState() =>
      _MealSuggestionContainerState();
}

class _MealSuggestionContainerState extends State<MealSuggestionContainer> {
  bool _isAdding = false;
  bool _isAdded = false;

  Future<void> _addToFoodLog() async {
    setState(() => _isAdding = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isAdding = false);
      return;
    }

    try {
      final today = DateTime.now();
      final foodLogId = '${user.uid}_${today.year}-${today.month}-${today.day}';

      // Get current food log or create new one
      final foodLogDoc = await FirebaseFirestore.instance
          .collection('food_logs')
          .doc(foodLogId)
          .get();

      Map<String, dynamic> foodLogData;
      List<Map<String, dynamic>> foods = [];

      if (foodLogDoc.exists) {
        foodLogData = foodLogDoc.data() as Map<String, dynamic>;
        foods = List<Map<String, dynamic>>.from(foodLogData['foods'] ?? []);
      } else {
        foodLogData = {
          'userId': user.uid,
          'date': Timestamp.fromDate(today),
          'totalCalories': 0,
          'totalProtein': 0,
          'totalCarbs': 0,
          'totalFat': 0,
          'foods': [],
        };
      }

      // Create the new food entry
      final newFood = {
        'mealName': widget.mealData['meal_name'],
        'servingSize': widget.mealData['serving_size'],
        'calories': widget.mealData['calories'],
        'protein': widget.mealData['protein'],
        'carbs': widget.mealData['carbs'],
        'fat': widget.mealData['fat'],
        'loggedTime': Timestamp.now(),
        'adjustmentType': 'percent',
        'adjustmentValue': 100.0,
      };

      // Update totals
      foodLogData['totalCalories'] =
          (foodLogData['totalCalories'] ?? 0) + widget.mealData['calories'];
      foodLogData['totalProtein'] =
          (foodLogData['totalProtein'] ?? 0) + widget.mealData['protein'];
      foodLogData['totalCarbs'] =
          (foodLogData['totalCarbs'] ?? 0) + widget.mealData['carbs'];
      foodLogData['totalFat'] =
          (foodLogData['totalFat'] ?? 0) + widget.mealData['fat'];

      // Add new food to list
      foods.add(newFood);
      foodLogData['foods'] = foods;

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('food_logs')
          .doc(foodLogId)
          .set(foodLogData);

      setState(() {
        _isAdding = false;
        _isAdded = true;
      });

      widget.onAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${widget.mealData['meal_name']} added successfully!')),
      );
    } catch (e) {
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding meal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mealData['meal_name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.mealData['serving_size'],
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroInfo('Calories', widget.mealData['calories']),
                    _buildMacroInfo('Protein', widget.mealData['protein'],
                        unit: 'g'),
                    _buildMacroInfo('Carbs', widget.mealData['carbs'],
                        unit: 'g'),
                    _buildMacroInfo('Fat', widget.mealData['fat'], unit: 'g'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _isAdded
              ? const Icon(Icons.check_circle, color: Colors.grey, size: 24)
              : IconButton(
                  icon: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle, color: Colors.grey),
                  onPressed: _isAdding ? null : _addToFoodLog,
                ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, dynamic value, {String unit = ''}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        Text(
          '$value$unit',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
