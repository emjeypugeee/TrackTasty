// recipe_container.dart
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class RecipeContainer extends StatelessWidget {
  final Map<String, dynamic> recipeData;

  const RecipeContainer({
    super.key,
    required this.recipeData,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipeData['recipe_name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Ingredients section
          const Text(
            'Ingredients:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ..._buildIngredientsList(),

          const SizedBox(height: 12),

          // Instructions section
          const Text(
            'Instructions:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ..._buildInstructionsList(),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientsList() {
    final ingredients = List<String>.from(recipeData['ingredients'] ?? []);
    return ingredients.map((ingredient) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '• $ingredient',
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
      );
    }).toList();
  }

  List<Widget> _buildInstructionsList() {
    final instructions = List<String>.from(recipeData['instructions'] ?? []);
    return instructions.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final instruction = entry.value;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$index. ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: instruction,
                style: TextStyle(color: Colors.grey[300], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildNutritionInfo() {
    final nutrition =
        recipeData['nutrition_per_serving'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition per serving:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          nutrition['serving_size'],
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMacroInfo('Calories', nutrition['calories']),
            _buildMacroInfo('Protein', nutrition['protein'], unit: 'g'),
            _buildMacroInfo('Carbs', nutrition['carbs'], unit: 'g'),
            _buildMacroInfo('Fat', nutrition['fat'], unit: 'g'),
          ],
        ),
      ],
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
