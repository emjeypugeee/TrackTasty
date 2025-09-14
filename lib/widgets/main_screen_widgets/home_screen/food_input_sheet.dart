import 'package:flutter/material.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/home_screen/macro_input.dart';

class FoodInputSheet extends StatefulWidget {
  final String? initialMealName;
  final double? initialCalories;
  final double? initialProtein;
  final double? initialCarbs;
  final double? initialFat;
  final String? initialServingSize;
  final Function(Map<String, dynamic>) onSubmit;
  final bool isEditing;

  const FoodInputSheet({
    super.key,
    this.initialMealName,
    this.initialCalories,
    this.initialProtein,
    this.initialCarbs,
    this.initialFat,
    this.initialServingSize,
    required this.onSubmit,
    this.isEditing = false,
  });

  @override
  State<FoodInputSheet> createState() => _FoodInputSheetState();
}

class _FoodInputSheetState extends State<FoodInputSheet> {
  late TextEditingController mealNameController;
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController carbsController;
  late TextEditingController fatController;
  late TextEditingController servingSizeController;

  bool _showAdvancedInput = false;

  // Adjustment controls
  String adjustmentType = 'percent'; // 'percent' or 'pieces'
  double adjustmentValue = 100.0; // percentage or quantity
  double originalCalories = 0;
  double originalProtein = 0;
  double originalCarbs = 0;
  double originalFat = 0;

  @override
  void initState() {
    super.initState();
    mealNameController =
        TextEditingController(text: widget.initialMealName ?? '');
    caloriesController =
        TextEditingController(text: _formatDouble(widget.initialCalories ?? 0));
    proteinController =
        TextEditingController(text: _formatDouble(widget.initialProtein ?? 0));
    carbsController =
        TextEditingController(text: _formatDouble(widget.initialCarbs ?? 0));
    fatController =
        TextEditingController(text: _formatDouble(widget.initialFat ?? 0));
    servingSizeController =
        TextEditingController(text: widget.initialServingSize ?? '1 serving');

    // Store original values
    originalCalories = widget.initialCalories?.toDouble() ?? 0;
    originalProtein = widget.initialProtein?.toDouble() ?? 0;
    originalCarbs = widget.initialCarbs?.toDouble() ?? 0;
    originalFat = widget.initialFat?.toDouble() ?? 0;
  }

  String _formatDouble(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  void _updateMacrosBasedOnAdjustment() {
    final factor =
        adjustmentType == 'percent' ? adjustmentValue / 100.0 : adjustmentValue;

    if (originalCalories > 0) {
      caloriesController.text = _formatDouble(originalCalories * factor);
    }
    if (originalProtein > 0) {
      proteinController.text = _formatDouble(originalProtein * factor);
    }
    if (originalCarbs > 0) {
      carbsController.text = _formatDouble(originalCarbs * factor);
    }
    if (originalFat > 0) {
      fatController.text = _formatDouble(originalFat * factor);
    }
  }

  void _onMacroChanged(String value) {
    // Update original values when user manually edits macros
    originalCalories = double.tryParse(caloriesController.text) ?? 0;
    originalProtein = double.tryParse(proteinController.text) ?? 0;
    originalCarbs = double.tryParse(carbsController.text) ?? 0;
    originalFat = double.tryParse(fatController.text) ?? 0;

    // Reset adjustment to 100% when user manually edits
    adjustmentValue = 100.0;
    setState(() {});
  }

  @override
  void dispose() {
    mealNameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    servingSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              widget.isEditing ? 'Edit Meal' : 'Add Meal',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Meal Name Input
            TextFormField(
              controller: mealNameController,
              decoration: InputDecoration(
                labelText: 'Meal Name',
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: const TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),

            // First row of macros - Calories and Protein
            Row(
              children: [
                // Calories Input
                Expanded(
                  child: MacroInput(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    controller: caloriesController,
                    onChanged: _onMacroChanged,
                    allowDecimals: true,
                  ),
                ),
                const SizedBox(width: 10),
                // Protein Input
                Expanded(
                  child: MacroInput(
                    icon: Icons.set_meal,
                    label: 'Protein',
                    controller: proteinController,
                    onChanged: _onMacroChanged,
                    allowDecimals: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Second row of macros - Carbs and Fats
            Row(
              children: [
                // Carbs Input
                Expanded(
                  child: MacroInput(
                    icon: Icons.grass,
                    label: 'Carbs',
                    controller: carbsController,
                    onChanged: _onMacroChanged,
                    allowDecimals: true,
                  ),
                ),
                const SizedBox(width: 10),
                // Fats Input
                Expanded(
                  child: MacroInput(
                    icon: Icons.icecream,
                    label: 'Fats',
                    controller: fatController,
                    onChanged: _onMacroChanged,
                    allowDecimals: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Advanced Input Toggle Button
            TextButton(
              onPressed: () {
                setState(() {
                  _showAdvancedInput = !_showAdvancedInput;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showAdvancedInput
                        ? 'Hide Advanced Input'
                        : 'Show Advanced Input',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                  Icon(
                    _showAdvancedInput
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),

            // Advanced Input Section
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: Visibility(
                visible: _showAdvancedInput,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Serving Size Input
                    TextFormField(
                      controller: servingSizeController,
                      decoration: InputDecoration(
                        labelText: 'Serving Size (e.g., "1 cup", "2 pieces")',
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    // Adjustment Section
                    _buildAdjustmentSection(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.primaryText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final mealData = {
                    'mealName': mealNameController.text,
                    'calories': double.tryParse(caloriesController.text) ?? 0,
                    'protein': double.tryParse(proteinController.text) ?? 0,
                    'carbs': double.tryParse(carbsController.text) ?? 0,
                    'fat': double.tryParse(fatController.text) ?? 0,
                    'servingSize': servingSizeController.text,
                  };
                  widget.onSubmit(mealData);
                },
                child: Text(widget.isEditing ? 'Update' : 'Add',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adjust Quantity:',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // Adjustment Type Selection (Tab-style buttons)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Use Expanded here to ensure buttons take equal space
              Expanded(
                child: _buildAdjustmentTabButton('percent', 'Percentage'),
              ),
              Expanded(
                child: _buildAdjustmentTabButton('pieces', 'Pieces'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // Adjustment Slider/Input
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: adjustmentValue,
                min: adjustmentType == 'percent' ? 0 : 1,
                max: adjustmentType == 'percent' ? 200 : 10,
                divisions: adjustmentType == 'percent' ? 200 : 9,
                label: adjustmentType == 'percent'
                    ? '${adjustmentValue.round()}%'
                    : '${adjustmentValue.round()}',
                onChanged: (value) {
                  setState(() {
                    adjustmentValue = adjustmentType == 'pieces'
                        ? value.roundToDouble()
                        : value;
                    _updateMacrosBasedOnAdjustment();
                  });
                },
                activeColor: AppColors.primaryColor,
                inactiveColor: Colors.grey[600],
                thumbColor: AppColors.primaryColor,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                adjustmentType == 'percent'
                    ? '${adjustmentValue.round()}%'
                    : '${adjustmentValue.round()}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdjustmentTabButton(String type, String title) {
    final isSelected = adjustmentType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          adjustmentType = type;
          if (adjustmentType == 'percent') {
            adjustmentValue = 100.0;
          } else {
            adjustmentValue = 1.0;
          }
          _updateMacrosBasedOnAdjustment();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
