import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MacroWarningUtils {
  // TEST FUNCTION - Call this to test if dialogs work at all
  static Future<void> testWarningDialog(BuildContext context) async {
    debugPrint('=== TESTING WARNING DARNING DIALOG ===');
    final testWarning = {
      'macro': 'Test Calories',
      'current': 1900,
      'goal': 2000,
      'percentage': 95,
      'unit': 'kcal',
      'color': Colors.orange,
      'isOverGoal': false,
    };
    await _showMacroWarningDialog(context, testWarning);
  }

  // Check if any macro is at or above 95% and show warnings
  static Future<void> checkAndShowMacroWarnings(
    BuildContext context,
    Map<String, dynamic> foodLogData,
  ) async {
    debugPrint('=== MACRO WARNING CHECK STARTED ===');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user logged in');
      return;
    }

    debugPrint('User ID: ${user.uid}');

    try {
      // Get user's macro goals
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();

      if (!userDoc.exists) {
        debugPrint('User document does not exist');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final calorieGoal = (userData['dailyCalories'] ?? 2000).toDouble();
      final proteinGoal = (userData['proteinGram'] ?? 100).toDouble();
      final carbsGoal = (userData['carbsGram'] ?? 250).toDouble();
      final fatGoal = (userData['fatsGram'] ?? 70).toDouble();

      debugPrint(
          'Goals - Calories: $calorieGoal, Protein: $proteinGoal, Carbs: $carbsGoal, Fat: $fatGoal');

      // Get current totals
      final totalCalories = (foodLogData['totalCalories'] ?? 0).toDouble();
      final totalProtein = (foodLogData['totalProtein'] ?? 0).toDouble();
      final totalCarbs = (foodLogData['totalCarbs'] ?? 0).toDouble();
      final totalFat = (foodLogData['totalFat'] ?? 0).toDouble();

      debugPrint(
          'Current - Calories: $totalCalories, Protein: $totalProtein, Carbs: $totalCarbs, Fat: $totalFat');

      // Calculate percentages
      final caloriePercent = (totalCalories / calorieGoal) * 100;
      final carbsPercent = (totalCarbs / carbsGoal) * 100;
      final proteinPercent = (totalProtein / proteinGoal) * 100;
      final fatPercent = (totalFat / fatGoal) * 100;

      debugPrint(
          'Percentages - Calories: ${caloriePercent.toStringAsFixed(1)}%, Carbs: ${carbsPercent.toStringAsFixed(1)}%, Protein: ${proteinPercent.toStringAsFixed(1)}%, Fat: ${fatPercent.toStringAsFixed(1)}%');

      debugPrint(
          'Percentages - Calories: ${caloriePercent.toStringAsFixed(1)}%, Carbs: ${carbsPercent.toStringAsFixed(1)}%, Protein: ${proteinPercent.toStringAsFixed(1)}%, Fat: ${fatPercent.toStringAsFixed(1)}%');

      // List of warnings in priority order: Calories > Carbs > Protein > Fat
      final List<Map<String, dynamic>> warnings = [];

      // TEMPORARY: Testing at 50% instead of 95% - Change back to 95 after testing!
      const double warningThreshold = 90.0; // Change back to 95.0 after testing

      debugPrint('Using warning threshold: $warningThreshold%');

      if (caloriePercent >= warningThreshold) {
        final isOverGoal = totalCalories > calorieGoal;
        debugPrint(
            '⚠️ CALORIES WARNING TRIGGERED: ${caloriePercent.toStringAsFixed(1)}% - Over goal: $isOverGoal');
        warnings.add({
          'macro': 'Calories',
          'current': totalCalories.toInt(),
          'goal': calorieGoal.toInt(),
          'percentage': caloriePercent.toInt(),
          'unit': 'kcal',
          'color': isOverGoal ? Colors.red : Colors.orange,
          'isOverGoal': isOverGoal,
        });
      }

      if (carbsPercent >= warningThreshold) {
        final isOverGoal = totalCarbs > carbsGoal;
        debugPrint(
            '⚠️ CARBS WARNING TRIGGERED: ${carbsPercent.toStringAsFixed(1)}% - Over goal: $isOverGoal');
        warnings.add({
          'macro': 'Carbohydrates',
          'current': totalCarbs.toInt(),
          'goal': carbsGoal.toInt(),
          'percentage': carbsPercent.toInt(),
          'unit': 'g',
          'color': isOverGoal ? Colors.red : Colors.blue,
          'isOverGoal': isOverGoal,
        });
      }

      if (proteinPercent >= warningThreshold) {
        final isOverGoal = totalProtein > proteinGoal;
        debugPrint(
            '⚠️ PROTEIN WARNING TRIGGERED: ${proteinPercent.toStringAsFixed(1)}% - Over goal: $isOverGoal');
        warnings.add({
          'macro': 'Protein',
          'current': totalProtein.toInt(),
          'goal': proteinGoal.toInt(),
          'percentage': proteinPercent.toInt(),
          'unit': 'g',
          'color': isOverGoal ? Colors.red : Colors.red,
          'isOverGoal': isOverGoal,
        });
      }

      if (fatPercent >= warningThreshold) {
        final isOverGoal = totalFat > fatGoal;
        debugPrint(
            '⚠️ FAT WARNING TRIGGERED: ${fatPercent.toStringAsFixed(1)}% - Over goal: $isOverGoal');
        warnings.add({
          'macro': 'Fat',
          'current': totalFat.toInt(),
          'goal': fatGoal.toInt(),
          'percentage': fatPercent.toInt(),
          'unit': 'g',
          'color': isOverGoal ? Colors.red : Colors.yellow,
          'isOverGoal': isOverGoal,
        });
      }

      debugPrint('Total warnings to show: ${warnings.length}');

      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('Context is not mounted, cannot show warnings');
        return;
      }

      // Show warnings one after another
      for (int i = 0; i < warnings.length; i++) {
        debugPrint(
            'Showing warning ${i + 1} of ${warnings.length}: ${warnings[i]['macro']}');
        await _showMacroWarningDialog(context, warnings[i]);
      }

      debugPrint('=== MACRO WARNING CHECK COMPLETED ===');
    } catch (e) {
      debugPrint('❌ Error checking macro warnings: $e');
    }
  }

  // Show individual macro warning dialog
  static Future<void> _showMacroWarningDialog(
    BuildContext context,
    Map<String, dynamic> warningData,
  ) async {
    if (!context.mounted) return;

    // Determine border color based on whether user is over goal
    final borderColor = warningData['isOverGoal'] ? Colors.red : Colors.orange;

    // Determine message based on whether user is over goal
    final String message;
    final String advice;

    if (warningData['isOverGoal']) {
      message =
          'You\'ve exceeded your daily ${warningData['macro'].toLowerCase()} goal by ${warningData['percentage'] - 100}%!';

      // Specific advice based on which macro is over goal
      switch (warningData['macro']) {
        case 'Calories':
          advice =
              'Consuming too many calories regularly can lead to weight gain, increased risk of chronic diseases, and reduced energy levels. Consider lighter meals for the rest of the day.';
          break;
        case 'Carbohydrates':
          advice =
              'Excessive carb intake can cause blood sugar spikes, energy crashes, and contribute to weight gain. Focus on protein and vegetables for remaining meals.';
          break;
        case 'Protein':
          advice =
              'Too much protein can strain kidneys, cause dehydration, and digestive issues. Balance your remaining meals with more vegetables and healthy fats.';
          break;
        case 'Fat':
          advice =
              'High fat consumption can lead to digestive discomfort, increased cholesterol, and weight gain. Choose leaner options for your remaining meals.';
          break;
        default:
          advice =
              'Consider choosing foods with lower ${warningData['macro'].toLowerCase()} content for the rest of the day to avoid excessive intake.';
      }
    } else {
      message =
          'You\'ve reached ${warningData['percentage']}% of your daily ${warningData['macro'].toLowerCase()} goal!';
      advice =
          'Consider choosing foods with lower ${warningData['macro'].toLowerCase()} content for the rest of the day to stay within your goal.';
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: borderColor.withOpacity(0.7),
              width: 3,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: borderColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                warningData['isOverGoal'] ? 'Critical Warning' : 'Warning',
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    warningData['isOverGoal']
                        ? Icons.error_outline
                        : Icons.notifications_active,
                    size: 60,
                    color: borderColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Warning message
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Current vs Goal
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          '${warningData['current']} ${warningData['unit']}',
                          style: TextStyle(
                            color: borderColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Goal:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          '${warningData['goal']} ${warningData['unit']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          warningData['isOverGoal'] ? 'Over by:' : 'Remaining:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          warningData['isOverGoal']
                              ? '${warningData['current'] - warningData['goal']} ${warningData['unit']}'
                              : '${warningData['goal'] - warningData['current']} ${warningData['unit']}',
                          style: TextStyle(
                            color: warningData['isOverGoal']
                                ? Colors.red
                                : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Advice text
              Text(
                advice,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: borderColor.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Got it!',
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }
}
