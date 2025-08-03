import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/components/percentage_slider.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class Userpreference7 extends StatefulWidget {
  const Userpreference7({super.key});

  @override
  State<Userpreference7> createState() => _Userpreference7();
}

class _Userpreference7 extends State<Userpreference7> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  /*
   * ===============================================================
   * Calculating recommended daily macro intake based on user inputs
   * ===============================================================
   */

  // default values
  double dailyCalories = 2000;
  double carbsPercentage = 50;
  double fatsPercentage = 30;
  double proteinPercentage = 20;

  // macronutrient values
  double carbsGram = 0;
  double fatsGram = 0;
  double proteinGram = 0;

  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.email)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // Retrieve user data
        final age = int.tryParse(data['age'] ?? '0') ?? 0;
        final measurementSystem = data['measurementSystem'] ?? 'metric';
        final gender = data['gender'] ?? 'male';
        final weight = double.tryParse(data['weight'] ?? '0') ?? 0;
        final height = double.tryParse(data['height'] ?? '0') ?? 0;
        final activityLevel = data['activitylevel'] ?? 'Sedentary';
        final goal = data['goal'] ?? 'Maintain Weight';

        // Converts weight and height to metric if necessary
        final isMetric = measurementSystem == 'metric';
        final weightKg = isMetric ? weight : weight * 0.453592; //
        final heightCm = isMetric ? height : height * 2.54; //

        // Calculate daily calories using Mifflin St. Jeor formula
        double bmr = gender == "male"
            ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
            : (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;

        // Adjust BMR based on activity level
        double activityMultiplier = _getActivityMultiplier(activityLevel);
        bmr *= activityMultiplier;

        // Adjust BMR based on goal
        bmr = _adjustCaloriesForGoal(bmr, goal);

        setState(() {
          dailyCalories = bmr;
          _calculateMacros();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      }
      debugPrint('Error fetching user data: $e');
    }
  }

  double _getActivityMultiplier(String activityLevel) {
    // determines multiplier based on activity level
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
        return 1.2; // Default to sedentary if unknown
    }
  }

  double _adjustCaloriesForGoal(double bmr, String goal) {
    // Adjusts BMR based on the user's goal
    switch (goal) {
      case "Mild Lose Weight":
        return bmr - 250; // 0.5 lb per week
      case "Lose Weight":
        return bmr - 500; // 1 lb per week
      case "Mild Gain Weight":
        return bmr + 250; // 0.5 lb per week
      case "Gain Weight":
        return bmr + 500; // 1 lb per week
      default:
        return bmr; // Maintain weight
    }
  }

  void _calculateMacros() {
    // Calculate macronutrient grams based on daily calories and percentages
    carbsGram = (dailyCalories * (carbsPercentage / 100)) / 4; // 4 cal per gram
    fatsGram = (dailyCalories * (fatsPercentage / 100)) / 9; // 9 cal per gram
    proteinGram =
        (dailyCalories * (proteinPercentage / 100)) / 4; // 4 cal per gram
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: LinearPercentIndicator(
          backgroundColor: AppColors.indicatorBg,
          progressColor: AppColors.indicatorProgress,
          percent: 1,
          barRadius: const Radius.circular(5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start your Nutrition Journey',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 22),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Thank you for providing your information! We\'re now calculating your personalized daily macronutrient recommendations based on your inputs',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Here\'s your recommended daily macronutrient intake. Feel free to adjust any of your information to match your progress!',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 35),
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
                                    color: AppColors.proteinColor,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      const Text(
                        'Adjust Macronutrient Percentages:',
                        style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Slider for Carbohydrates
                      PercentageSlider(
                        value: carbsPercentage,
                        label: 'Carbs',
                        activeColor: AppColors.carbsColor,
                        labelColor: AppColors.primaryText,
                        min: 40.0,
                        max: 60.0,
                        onChanged: (value) {
                          setState(() {
                            final remaining =
                                100 - proteinPercentage - fatsPercentage;
                            carbsPercentage = value.clamp(0, remaining);
                            _calculateMacros();
                          });
                        },
                      ),

                      // Slider for Fats
                      PercentageSlider(
                        value: fatsPercentage,
                        label: 'Fats',
                        activeColor: AppColors.fatColor,
                        labelColor: AppColors.primaryText,
                        min: 20.0,
                        max: 35.0,
                        onChanged: (value) {
                          setState(() {
                            final remaining =
                                100 - proteinPercentage - carbsPercentage;
                            fatsPercentage = value.clamp(0, remaining);
                            _calculateMacros();
                          });
                        },
                      ),

                      // Slider for Protein
                      PercentageSlider(
                        value: proteinPercentage,
                        label: 'Protein',
                        activeColor: AppColors.proteinColor,
                        labelColor: AppColors.primaryText,
                        min: 20.0,
                        max: 35.0,
                        onChanged: (value) {
                          setState(() {
                            final remaining =
                                100 - carbsPercentage - fatsPercentage;
                            proteinPercentage = value.clamp(0, remaining);
                            _calculateMacros();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // MACROS

              const SizedBox(height: 20),

              //lower buttons back and continue button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    //back button with gesture detectore
                    CustomTextButton(
                        title: 'Back',
                        onTap: () {
                          context.push('/preference6');
                        },
                        size: 16),

                    SizedBox(width: 50),

                    //continue button
                    Expanded(
                      child: MyButtons(
                        text: 'Next',
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            // Save the calculated macros to firestore
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection("Users")
                                  .doc(user.email)
                                  .update({
                                'dailyCalories': dailyCalories,
                                'carbsPercentage': carbsPercentage,
                                'fatsPercentage': fatsPercentage,
                                'proteinPercentage': proteinPercentage,
                                'carbsGram': carbsGram,
                                'fatsGram': fatsGram,
                                'proteinGram': proteinGram
                              });
                            }

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Saved!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.snackBarBgSaved,
                            ));
                            context.push('/home');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
