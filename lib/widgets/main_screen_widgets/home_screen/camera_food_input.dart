import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:flutter/material.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/home_screen/macro_input.dart';

class CameraFoodInputSheet extends StatefulWidget {
  final String? initialMealName;
  final int? initialCalories;
  final int? initialProtein;
  final int? initialCarbs;
  final int? initialFat;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onTakePhoto;
  final Function(Map<String, dynamic>) onGallery;
  final bool isEditing;

  const CameraFoodInputSheet(
      {super.key,
      this.initialMealName,
      this.initialCalories,
      this.initialProtein,
      this.initialCarbs,
      this.initialFat,
      required this.onSubmit,
      this.isEditing = false,
      required this.onTakePhoto,
      required this.onGallery});

  @override
  State<CameraFoodInputSheet> createState() => _CameraFoodInputSheet();
}

class _CameraFoodInputSheet extends State<CameraFoodInputSheet> {
  late TextEditingController mealNameController;
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController carbsController;
  late TextEditingController fatController;

  @override
  void initState() {
    super.initState();
    mealNameController =
        TextEditingController(text: widget.initialMealName ?? '');
    caloriesController =
        TextEditingController(text: widget.initialCalories?.toString() ?? '');
    proteinController =
        TextEditingController(text: widget.initialProtein?.toString() ?? '');
    carbsController =
        TextEditingController(text: widget.initialCarbs?.toString() ?? '');
    fatController =
        TextEditingController(text: widget.initialFat?.toString() ?? '');
  }

  @override
  void dispose() {
    mealNameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
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
            Text(
              'Add Meal',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(
              height: 20,
            ),
            //camera thing
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Image preview container
                Expanded(
                  child: Container(
                    height: 115,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child:
                        const Icon(Icons.image, color: Colors.grey, size: 40),
                  ),
                ),

                const SizedBox(width: 12), // Spacing

                // Upload button
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    MyButtons(
                      text: 'Take a photo',
                      onTap: () {
                        // Add your upload logic here
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ), // Spacing

                    // Take photo button
                    MyButtons(
                      text: 'Upload a photo',
                      onTap: () {
                        // Add your camera logic here
                      },
                    ),
                  ],
                ),
              ],
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

            // Macros Input
            Row(
              children: [
                // Calories Input
                MacroInput(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  controller: caloriesController,
                ),
                const SizedBox(width: 10),
                // Protein Input
                MacroInput(
                  icon: Icons.set_meal,
                  label: 'Protein',
                  controller: proteinController,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Carbs Input
                MacroInput(
                  icon: Icons.grass,
                  label: 'Carbs',
                  controller: carbsController,
                ),
                const SizedBox(width: 10),
                // Fats Input
                MacroInput(
                  icon: Icons.icecream,
                  label: 'Fats',
                  controller: fatController,
                ),
              ],
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
                    'calories': int.tryParse(caloriesController.text) ?? 0,
                    'protein': int.tryParse(proteinController.text) ?? 0,
                    'carbs': int.tryParse(carbsController.text) ?? 0,
                    'fat': int.tryParse(fatController.text) ?? 0,
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
}
