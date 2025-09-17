import 'package:fitness/model/food_item.dart';
import 'package:flutter/material.dart';

class FoodAnalysisDialog extends StatefulWidget {
  final String analysisResult;
  final List<FoodItem> mealSuggestions;
  final Function(FoodItem) onAddMeal;

  const FoodAnalysisDialog({
    Key? key,
    required this.analysisResult,
    required this.mealSuggestions,
    required this.onAddMeal,
  }) : super(key: key);

  @override
  _FoodAnalysisDialogState createState() => _FoodAnalysisDialogState();
}

class _FoodAnalysisDialogState extends State<FoodAnalysisDialog> {
  int _selectedSuggestionIndex = 0; // Default to first suggestion

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      insetPadding: EdgeInsets.all(20),
      child: Container(
        padding: EdgeInsets.all(16),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Food Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // For DEBUGGING purposes, shows the chat of the GEMINI API
              /*
              SizedBox(height: 16),
              Text(
                widget.analysisResult,
                style: TextStyle(color: Colors.white70),
              ),
              */
              SizedBox(height: 16),
              Text(
                'Meal Suggestions:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ...widget.mealSuggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final suggestion = entry.value;

                return Card(
                  color: _selectedSuggestionIndex == index
                      ? Colors.blue[800]
                      : Colors.grey[800],
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      suggestion.mealName,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serving: ${suggestion.servingSize}',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Cal: ${suggestion.calories} | P: ${suggestion.protein}g | C: ${suggestion.carbs}g | F: ${suggestion.fat}g',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedSuggestionIndex = index;
                      });
                    },
                  ),
                );
              }).toList(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child:
                        Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.mealSuggestions.isNotEmpty) {
                        widget.onAddMeal(
                            widget.mealSuggestions[_selectedSuggestionIndex]);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Add Meal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
