// recalculate_macros_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/components/percentage_slider.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class RecalculateMacrosPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String selectedGoal;

  const RecalculateMacrosPage({
    super.key,
    required this.userData,
    required this.selectedGoal,
  });

  @override
  State<RecalculateMacrosPage> createState() => _RecalculateMacrosPageState();
}

class _RecalculateMacrosPageState extends State<RecalculateMacrosPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Default values
  double dailyCalories = 2000;
  double carbsPercentage = 50;
  double fatsPercentage = 30;
  double proteinPercentage = 20;

  // Lock feature
  bool _lockCarbs = false;
  bool _lockFats = false;
  bool _lockProtein = false;
  double _lockedCarbsValue = 50;
  double _lockedFatsValue = 30;
  double _lockedProteinValue = 20;

  // Macronutrient values
  double carbsGram = 0;
  double fatsGram = 0;
  double proteinGram = 0;

  // Form controllers
  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  String? selectedGender;
  String? selectedActivityLevel;
  String? selectedGoal;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final data = widget.userData;

    // Debug: print what's in userData
    debugPrint("UserData received: ${data.toString()}");

    // Set initial values from userData
    weightController.text = data['weight']?.toString() ?? '';
    heightController.text = data['height']?.toString() ?? '';
    selectedGender = data['gender'] ?? 'male';
    selectedActivityLevel = data['selectedActivityLevel'] ?? 'Sedentary';
    selectedGoal = data['goal'] ?? 'Maintain Weight';

    // Debug: print what we're setting
    debugPrint("Setting weight: ${weightController.text}");
    debugPrint("Setting height: ${heightController.text}");

    // Set initial macro percentages if they exist
    if (data['carbsPercentage'] != null)
      carbsPercentage = data['carbsPercentage'].toDouble();
    if (data['fatsPercentage'] != null)
      fatsPercentage = data['fatsPercentage'].toDouble();
    if (data['proteinPercentage'] != null)
      proteinPercentage = data['proteinPercentage'].toDouble();

    // Now calculate macros after initializing all values
    _calculateMacros();
  }

  void _calculateMacros() {
    // Parse form values with defaults
    final age = int.tryParse(widget.userData['age']?.toString() ?? '0') ?? 0;
    final measurementSystem = widget.userData['measurementSystem'] ?? 'metric';
    final weight = widget.userData['weight'] ?? 0;
    final height = widget.userData['height'] ?? 0;

    debugPrint("Current age: $age");
    debugPrint("Measurement System: $measurementSystem");
    debugPrint("Raw weight: $weight");
    debugPrint("Raw height: $height");

    // Use safe defaults if selections are null
    final gender = selectedGender ?? 'male';
    final activityLevel = selectedActivityLevel ?? 'Sedentary';
    final goal = selectedGoal ?? 'Maintain Weight';

    debugPrint("Current gender: $gender");
    debugPrint("Current activity level: $activityLevel");
    debugPrint("Current goal: $goal");

    // Convert weight and height to metric if necessary
    final isMetric = measurementSystem == 'Metric';
    final weightKg = isMetric ? weight : weight * 0.453592;

    // FIX: Height conversion logic - if metric, use as-is (cm), if imperial, convert inches to cm
    final heightCm = isMetric ? height : height * 2.54;

    debugPrint("Converted weight (kg): $weightKg");
    debugPrint("Converted height (cm): $heightCm");

    // Calculate daily calories using Mifflin St. Jeor formula
    double bmr = gender == "male"
        ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
        : (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;

    debugPrint("Current BMR: $bmr");

    // Adjust BMR based on activity level
    double activityMultiplier = _getActivityMultiplier(activityLevel);
    bmr *= activityMultiplier;

    debugPrint("Current activity multiplier: $activityMultiplier");

    // Adjust BMR based on goal
    bmr = _adjustCaloriesForGoal(bmr, goal);

    debugPrint("Adjusted bmr: $bmr");

    setState(() {
      dailyCalories = bmr;
      _updateMacroGrams();
    });
  }

  double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel) {
      case 'Sedentary':
        return 1.2;
      case 'Lightly active':
        return 1.375;
      case 'Moderately active':
        return 1.55;
      case 'Very active':
        return 1.725;
      case 'Extra active':
        return 1.9;
      default:
        return 1.2;
    }
  }

  double _adjustCaloriesForGoal(double bmr, String goal) {
    switch (goal) {
      case "Mild Lose Weight":
        return bmr - 250;
      case "Lose Weight":
        return bmr - 500;
      case "Mild Gain Weight":
        return bmr + 250;
      case "Gain Weight":
        return bmr + 500;
      default:
        return bmr;
    }
  }

  void _updateMacroGrams() {
    carbsGram = (dailyCalories * (carbsPercentage / 100)) / 4;
    fatsGram = (dailyCalories * (fatsPercentage / 100)) / 9;
    proteinGram = (dailyCalories * (proteinPercentage / 100)) / 4;

    debugPrint("Current carbs: $carbsGram");
    debugPrint("Current fats: $fatsGram");
    debugPrint("Current protein: $proteinGram");
  }

  void _normalizeMacros() {
    double total = carbsPercentage + fatsPercentage + proteinPercentage;
    if (total != 100) {
      double adjustment = 100 - total;
      int unlockedCount =
          (_lockCarbs ? 0 : 1) + (_lockFats ? 0 : 1) + (_lockProtein ? 0 : 1);

      if (unlockedCount > 0) {
        double perMacroAdjustment = adjustment / unlockedCount;

        if (!_lockCarbs) {
          carbsPercentage += perMacroAdjustment;
          carbsPercentage = carbsPercentage.clamp(40.0, 60.0);
        }
        if (!_lockFats) {
          fatsPercentage += perMacroAdjustment;
          fatsPercentage = fatsPercentage.clamp(20.0, 35.0);
        }
        if (!_lockProtein) {
          proteinPercentage += perMacroAdjustment;
          proteinPercentage = proteinPercentage.clamp(20.0, 35.0);
        }
      }
    }
    _updateMacroGrams();
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update weight in weight_logs if it has changed
      final currentWeight = double.tryParse(weightController.text) ?? 0;
      final oldWeight = widget.userData['weight'] is double
          ? widget.userData['weight'] as double
          : double.tryParse(widget.userData['weight']?.toString() ?? '0') ?? 0;

      if (currentWeight != oldWeight) {
        final today = DateTime.now();
        await FirebaseFirestore.instance
            .collection('weight_history')
            .doc('${user.uid}_${DateFormat('yyyy-MM-dd').format(today)}')
            .set({
          'userId': user.uid,
          'weight': currentWeight,
          'date': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      // Update user data in Firestore
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.email)
          .update({
        'age': int.tryParse(widget.userData['age']?.toString() ?? '0') ?? 0,
        'weight': currentWeight,
        'height': double.tryParse(heightController.text) ?? 0,
        'gender': selectedGender,
        'selectedActivityLevel': selectedActivityLevel,
        'goal': selectedGoal,
        'dailyCalories': dailyCalories,
        'carbsPercentage': carbsPercentage,
        'fatsPercentage': fatsPercentage,
        'proteinPercentage': proteinPercentage,
        'carbsGram': carbsGram,
        'fatsGram': fatsGram,
        'proteinGram': proteinGram
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Macros recalculated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Recalculate Macros',
            style: TextStyle(color: AppColors.primaryText)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryText,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display calculated macros
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 50),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 32, 32, 32),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.buttonColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Calories Text
                            Text(
                              'Daily Calories',
                              style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${dailyCalories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(
                                  color: AppColors.caloriesColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),

                            // Carbs Text
                            Text(
                              'Carbs (${carbsPercentage.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                  color: AppColors.primaryText, fontSize: 16),
                            ),
                            Text(
                              '${carbsGram.toStringAsFixed(0)}g',
                              style: const TextStyle(
                                  color: AppColors.carbsColor, fontSize: 16),
                            ),
                            const SizedBox(height: 10),

                            // Fats Text
                            Text(
                              'Fats (${fatsPercentage.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                  color: AppColors.primaryText, fontSize: 16),
                            ),
                            Text(
                              '${fatsGram.toStringAsFixed(0)} g',
                              style: const TextStyle(
                                  color: AppColors.fatColor, fontSize: 16),
                            ),
                            const SizedBox(height: 10),

                            // Protein Text
                            Text(
                              'Protein (${proteinPercentage.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                  color: AppColors.primaryText, fontSize: 16),
                            ),
                            Text(
                              '${proteinGram.toStringAsFixed(0)} g',
                              style: const TextStyle(
                                  color: AppColors.proteinColor, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'Adjust Macronutrient Percentages:',
                      style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Slider for Carbs
                    _buildMacroSlider(
                      label: 'Carbs',
                      color: AppColors.carbsColor,
                      currentValue: carbsPercentage,
                      lockedValue: _lockedCarbsValue,
                      isLocked: _lockCarbs,
                      onLockToggle: () {
                        setState(() {
                          _lockCarbs = !_lockCarbs;
                          if (_lockCarbs) _lockedCarbsValue = carbsPercentage;
                          _normalizeMacros();
                        });
                      },
                      onValueChanged: (newValue) {
                        if (_lockCarbs) return;
                        setState(() {
                          carbsPercentage = newValue.clamp(40.0, 60.0);
                          _normalizeMacros();
                        });
                      },
                      min: 40.0,
                      max: 60.0,
                    ),
                    const SizedBox(height: 10),

                    // Slider for Fats
                    _buildMacroSlider(
                      label: 'Fats',
                      color: AppColors.fatColor,
                      currentValue: fatsPercentage,
                      lockedValue: _lockedFatsValue,
                      isLocked: _lockFats,
                      onLockToggle: () {
                        setState(() {
                          _lockFats = !_lockFats;
                          if (_lockFats) _lockedFatsValue = fatsPercentage;
                          _normalizeMacros();
                        });
                      },
                      onValueChanged: (newValue) {
                        if (_lockFats) return;
                        setState(() {
                          fatsPercentage = newValue.clamp(20.0, 35.0);
                          _normalizeMacros();
                        });
                      },
                      min: 20.0,
                      max: 35.0,
                    ),
                    const SizedBox(height: 10),

                    // Slider for Protein
                    _buildMacroSlider(
                      label: 'Protein',
                      color: AppColors.proteinColor,
                      currentValue: proteinPercentage,
                      lockedValue: _lockedProteinValue,
                      isLocked: _lockProtein,
                      onLockToggle: () {
                        setState(() {
                          _lockProtein = !_lockProtein;
                          if (_lockProtein)
                            _lockedProteinValue = proteinPercentage;
                          _normalizeMacros();
                        });
                      },
                      onValueChanged: (newValue) {
                        if (_lockProtein) return;
                        setState(() {
                          proteinPercentage = newValue.clamp(20.0, 35.0);
                          _normalizeMacros();
                        });
                      },
                      min: 20.0,
                      max: 35.0,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Save button
            MyButtons(
              text: 'Save New Macros',
              onTap: () async {
                await _saveUserData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSlider({
    required String label,
    required Color color,
    required double currentValue,
    required double lockedValue,
    required bool isLocked,
    required VoidCallback onLockToggle,
    required ValueChanged<double> onValueChanged,
    required double min,
    required double max,
  }) {
    final displayValue = isLocked ? lockedValue : currentValue;

    return PercentageSlider(
      value: displayValue,
      label: label,
      activeColor: color,
      labelColor: AppColors.primaryText,
      min: min,
      max: max,
      isLocked: isLocked,
      onLockToggle: onLockToggle,
      onChanged: (dynamic value) => onValueChanged(value.toDouble()),
    );
  }
}
