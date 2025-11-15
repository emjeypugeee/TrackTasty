import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/edit_goal_sheet.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/goal_celebration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GoalAchievementUtils {
  /// Test function to display achievement and goal change
  static void testGoalAchievement(BuildContext context) {
    debugPrint("🧪 TEST: Goal Achievement Functionality");

    // Simulate different scenarios
    final testScenarios = [
      {'goalType': 'Lose Weight', 'current': 70.0, 'goal': 65.0, 'new': 64.5},
      {'goalType': 'Gain Weight', 'current': 60.0, 'goal': 65.0, 'new': 65.5},
      {
        'goalType': 'Maintain Weight',
        'current': 70.0,
        'goal': 70.0,
        'new': 70.2
      },
    ];

    for (final scenario in testScenarios) {
      debugPrint("📋 Testing: ${scenario['goalType']}");
      debugPrint(
          "   Current: ${scenario['current']}kg, Goal: ${scenario['goal']}kg");
      debugPrint("   New Weight: ${scenario['new']}kg");

      // Simulate achievement check
      final isAchieved = _simulateAchievementCheck(
        scenario['goalType'] as String,
        scenario['new'] as double,
        scenario['goal'] as double,
      );

      debugPrint("   ✅ Goal Achieved: $isAchieved");
    }

    // Test the floating windows with a simulated achievement
    _testFloatingWindows(context);
  }

  /// Test the floating windows with simulated data
  static void _testFloatingWindows(BuildContext context) {
    final testAchievement = {
      'goalType': 'Lose Weight',
      'initialWeight': 70.0,
      'goalWeight': 65.0,
      'achievedWeight': 64.5,
      'measurementSystem': 'Metric',
      'isAchieved': true,
    };

    // Show the celebration dialog
    showGoalCelebrationDialog(context, testAchievement);
  }

  /// Debug method to check goal achievement conditions
  static void debugGoalAchievementConditions({
    required double newWeight,
    required double goalWeight,
    required String goalType,
    required double initialWeight,
  }) {
    debugPrint("🎯 DEBUG GOAL ACHIEVEMENT CONDITIONS:");
    debugPrint("   - New Weight: $newWeight");
    debugPrint("   - Goal Weight: $goalWeight");
    debugPrint("   - Initial Weight: $initialWeight");
    debugPrint("   - Goal Type: $goalType");

    bool goalAchieved = false;
    String condition = "";

    switch (goalType) {
      case 'Lose Weight':
      case 'Mild Lose Weight':
        goalAchieved = newWeight <= goalWeight;
        condition = "$newWeight <= $goalWeight";
        debugPrint("   - Lose Weight Condition: $condition");
        break;

      case 'Gain Weight':
      case 'Mild Gain Weight':
        goalAchieved = newWeight >= goalWeight;
        condition = "$newWeight >= $goalWeight";
        debugPrint("   - Gain Weight Condition: $condition");
        break;

      case 'Maintain Weight':
        final tolerance = goalWeight * 0.02;
        goalAchieved = (newWeight - goalWeight).abs() <= tolerance;
        condition = "|$newWeight - $goalWeight| <= $tolerance";
        debugPrint("   - Maintain Weight Condition: $condition");
        break;

      default:
        debugPrint("   - ❌ Unknown goal type: $goalType");
        goalAchieved = false;
    }

    debugPrint("   - ✅ Goal Achieved: $goalAchieved");
    debugPrint("   - 📊 Difference: ${(newWeight - goalWeight).abs()}");

    if (goalAchieved) {
      debugPrint("   - 🎉 CONDITION MET! Goal achievement should trigger!");
    } else {
      debugPrint("   - ⏳ Condition not met yet. Keep going!");
    }
  }

  static bool _simulateAchievementCheck(
      String goalType, double newWeight, double goalWeight) {
    switch (goalType) {
      case 'Lose Weight':
      case 'Mild Lose Weight':
        return newWeight <= goalWeight;
      case 'Gain Weight':
      case 'Mild Gain Weight':
        return newWeight >= goalWeight;
      case 'Maintain Weight':
        final tolerance = goalWeight * 0.02;
        return (newWeight - goalWeight).abs() <= tolerance;
      default:
        return false;
    }
  }

  /// Save goal when user sets it in edit goal sheet
  static Future<void> saveUserGoal({
    required String userId,
    required String userEmail,
    required String goalType,
    required double goalWeight,
    required double currentWeight,
    required String measurementSystem,
  }) async {
    try {
      final achievementDoc = FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId);

      final achievementSnapshot = await achievementDoc.get();
      final currentData = achievementSnapshot.data() ?? {};
      final goalAchievements =
          currentData['goal_achievements'] as List<dynamic>? ?? [];

      // Clean up unachieved goals before adding new one
      final cleanedAchievements = goalAchievements.where((achievement) {
        final isAchieved = achievement['isAchieved'] == true;
        return isAchieved; // Keep only achieved goals
      }).toList();

      // Create new goal entry with progress tracking
      final newGoal = {
        'goalType': goalType,
        'initialWeight': currentWeight,
        'goalWeight': goalWeight,
        'achievedWeight': currentWeight, // Start with current weight
        'measurementSystem': measurementSystem,
        'isAchieved': false, // Not achieved yet
        'createdDate': Timestamp.now(),
        'achievementDate': null, // Will be set when achieved
        'foodLogsSinceGoal': 0, // Track food logs since goal creation
        'weightChangesSinceGoal': 0, // Track weight changes since goal creation
      };

      // Add new goal to the array
      cleanedAchievements.add(newGoal);

      // Update the document
      await achievementDoc.set({
        'goal_achievements': cleanedAchievements,
      }, SetOptions(merge: true));

      debugPrint('✅ New goal saved successfully with progress tracking');
      debugPrint('   - Goal Type: $goalType');
      debugPrint('   - Goal Weight: $goalWeight');
      debugPrint('   - Initial Weight: $currentWeight');
      debugPrint('   - Progress tracking initialized');
    } catch (e) {
      debugPrint('❌ Error saving user goal: $e');
      rethrow;
    }
  }

  /// Check if user has achieved their goal based on new weight
  static Future<Map<String, dynamic>?> checkGoalAchievement({
    required BuildContext context,
    required double newWeight,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        debugPrint("❌ No user logged in");
        return null;
      }

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();

      if (!userDoc.exists) {
        debugPrint("❌ User document doesn't exist");
        return null;
      }

      final userData = userDoc.data()!;
      final goalType = userData['goal'] as String?;
      final goalWeight = userData['goalWeight'] as num?;
      final measurementSystem = userData['measurementSystem'] as String?;

      if (goalType == null || goalWeight == null) {
        debugPrint(
            "❌ Missing goal data: goalType=$goalType, goalWeight=$goalWeight");
        return null;
      }

      // For new goal achievements, use current weight as initial weight
      final initialWeightValue = userData['weight'];
      final initialWeight = initialWeightValue is int
          ? initialWeightValue.toDouble()
          : initialWeightValue as double? ?? newWeight;

      // DEBUG: Print achievement conditions
      debugGoalAchievementConditions(
        newWeight: newWeight,
        goalWeight: goalWeight.toDouble(),
        goalType: goalType,
        initialWeight: initialWeight.toDouble(),
      );

      // Check if goal is achieved based on goal type
      bool goalAchieved = false;

      switch (goalType) {
        case 'Lose Weight':
        case 'Mild Lose Weight':
          goalAchieved = newWeight <= goalWeight;
          break;

        case 'Gain Weight':
        case 'Mild Gain Weight':
          goalAchieved = newWeight >= goalWeight;
          break;

        case 'Maintain Weight':
          final tolerance = goalWeight * 0.02;
          goalAchieved = (newWeight - goalWeight).abs() <= tolerance;
          break;

        default:
          debugPrint("❌ Unknown goal type: $goalType");
          return null;
      }

      debugPrint("🎯 Final Goal Achievement Status: $goalAchieved");

      // If goal is achieved, check requirements
      if (goalAchieved) {
        debugPrint("🔍 Checking goal achievement requirements...");

        final meetsRequirements = await _checkGoalAchievementRequirements(
          userId: user.uid,
          goalType: goalType,
          goalWeight: goalWeight.toDouble(),
        );

        if (!meetsRequirements) {
          debugPrint("❌ Goal weight reached but requirements not met");
          return null;
        }

        // Check if this achievement was already recorded
        final isNewAchievement = await _isNewAchievement(
          userId: user.uid,
          goalType: goalType,
          goalWeight: goalWeight.toDouble(),
        );

        if (!isNewAchievement) {
          debugPrint(
              '📝 Goal already achieved previously - skipping celebration');
          return null;
        }

        // Update the achievement in Firestore
        await _markGoalAsAchieved(
          userId: user.uid,
          goalType: goalType,
          goalWeight: goalWeight.toDouble(),
          achievedWeight: newWeight,
        );

        final achievementData = {
          'goalType': goalType,
          'initialWeight': initialWeight.toDouble(),
          'goalWeight': goalWeight.toDouble(),
          'achievedWeight': newWeight,
          'measurementSystem': measurementSystem ?? 'Metric',
          'isAchieved': true,
          'achievementDate': Timestamp.now(),
        };

        debugPrint('🎉 NEW GOAL ACHIEVEMENT DETECTED! Requirements met!');
        debugPrint('   - Achievement Data: $achievementData');

        return achievementData;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error checking goal achievement: $e');
      return null;
    }
  }

  /// Check if user meets the goal achievement requirements
  static Future<bool> _checkGoalAchievementRequirements({
    required String userId,
    required String goalType,
    required double goalWeight,
  }) async {
    try {
      debugPrint("🔍 Checking goal achievement requirements...");

      final achievementDoc = await FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId)
          .get();

      if (!achievementDoc.exists) {
        debugPrint("❌ No achievements document found");
        return false;
      }

      final achievementData = achievementDoc.data()!;
      final goalAchievements =
          achievementData['goal_achievements'] as List<dynamic>? ?? [];

      // Find the current goal
      Map<String, dynamic>? currentGoal;
      for (final achievement in goalAchievements) {
        final goal = achievement as Map<String, dynamic>;
        final existingGoalType = goal['goalType'] as String?;
        final existingGoalWeightValue = goal['goalWeight'];
        final existingGoalWeight = existingGoalWeightValue is int
            ? existingGoalWeightValue.toDouble()
            : existingGoalWeightValue as double?;
        final isAchieved = goal['isAchieved'] == true;

        if (existingGoalType == goalType &&
            existingGoalWeight == goalWeight &&
            !isAchieved) {
          currentGoal = goal;
          break;
        }
      }

      if (currentGoal == null) {
        debugPrint("❌ Current goal not found or already achieved");
        return false;
      }

      // Get requirement tracking data
      final foodLogsSinceGoal = currentGoal['foodLogsSinceGoal'] ?? 0;
      final weightChangesSinceGoal = currentGoal['weightChangesSinceGoal'] ?? 0;
      final goalCreatedDate = currentGoal['createdDate'] as Timestamp;

      debugPrint("📊 Current progress:");
      debugPrint("   - Food logs since goal: $foodLogsSinceGoal/7");
      debugPrint("   - Weight changes since goal: $weightChangesSinceGoal/2");
      debugPrint("   - Goal created: ${goalCreatedDate.toDate()}");

      // Check requirements - MODIFIED LOGIC
      final hasEnoughFoodLogs = foodLogsSinceGoal >= 7;

      // If user has 7/7 food logs and 1/2 weight changes,
      // the current weight update will count as the 2nd weight change
      final hasEnoughWeightChanges = weightChangesSinceGoal >= 2 ||
          (hasEnoughFoodLogs && weightChangesSinceGoal == 1);

      debugPrint("✅ Requirements status:");
      debugPrint("   - 7+ food logs: $hasEnoughFoodLogs");
      debugPrint(
          "   - 2+ weight changes (or 1 with 7 food logs): $hasEnoughWeightChanges");

      return hasEnoughFoodLogs && hasEnoughWeightChanges;
    } catch (e) {
      debugPrint('❌ Error checking goal requirements: $e');
      return false;
    }
  }

  /// Show goal celebration dialog
  static Future<void> showGoalCelebration(
      BuildContext context, Map<String, dynamic> achievementData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          GoalCelebrationDialog(achievementData: achievementData),
    );
  }

  /// Update goal progress tracking
  static Future<void> updateGoalProgress({
    required String userId,
    required String updateType, // 'food_log' or 'weight_change'
  }) async {
    try {
      // For weight changes, check if user already changed weight today
      if (updateType == 'weight_change') {
        final today = DateTime.now();
        final todayString =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // Check weight_history collection for today's entry
        final weightHistoryDoc = await FirebaseFirestore.instance
            .collection('weight_history')
            .doc('${userId}_$todayString')
            .get();

        // If weight was already changed today and this is not the first change, don't count it
        // EXCEPTION: If this is the weight change that achieves the goal and user has 7/7 food logs + 1/2 weight changes,
        // we should allow it to count as the final requirement
        if (weightHistoryDoc.exists) {
          debugPrint(
              "📊 Weight already changed today - checking if this is goal-achieving weight change");

          // Check if this weight change might achieve a goal
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && user.email != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.email)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final goalType = userData['goal'] as String?;
              final goalWeight = userData['goalWeight'] as num?;
              final currentWeight = userData['weight'] as num?;

              if (goalType != null &&
                  goalWeight != null &&
                  currentWeight != null) {
                // Check if this weight change would achieve the goal
                bool wouldAchieveGoal = false;
                switch (goalType) {
                  case 'Lose Weight':
                  case 'Mild Lose Weight':
                    wouldAchieveGoal =
                        currentWeight.toDouble() <= goalWeight.toDouble();
                    break;
                  case 'Gain Weight':
                  case 'Mild Gain Weight':
                    wouldAchieveGoal =
                        currentWeight.toDouble() >= goalWeight.toDouble();
                    break;
                  case 'Maintain Weight':
                    final tolerance = goalWeight.toDouble() * 0.02;
                    wouldAchieveGoal =
                        (currentWeight.toDouble() - goalWeight.toDouble())
                                .abs() <=
                            tolerance;
                    break;
                }

                if (wouldAchieveGoal) {
                  debugPrint(
                      "🎯 This weight change achieves goal - allowing progress update");
                  // Continue with the progress update since this weight change achieves the goal
                } else {
                  debugPrint(
                      "📊 Weight already changed today - not counting as additional weight change");
                  return; // Exit without counting this as a new weight change
                }
              }
            }
          } else {
            debugPrint(
                "📊 Weight already changed today - not counting as additional weight change");
            return; // Exit without counting this as a new weight change
          }
        }
      }

      final achievementDoc = FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId);

      final achievementSnapshot = await achievementDoc.get();
      if (!achievementSnapshot.exists) return;

      final achievementData = achievementSnapshot.data()!;
      final goalAchievements =
          achievementData['goal_achievements'] as List<dynamic>? ?? [];

      // Update all unachieved goals
      bool needsUpdate = false;
      for (int i = 0; i < goalAchievements.length; i++) {
        final goal = goalAchievements[i] as Map<String, dynamic>;
        final isAchieved = goal['isAchieved'] == true;

        if (!isAchieved) {
          if (updateType == 'food_log') {
            final currentLogs = goal['foodLogsSinceGoal'] ?? 0;
            goalAchievements[i] = {
              ...goal,
              'foodLogsSinceGoal': currentLogs + 1,
            };
            needsUpdate = true;
          } else if (updateType == 'weight_change') {
            final currentChanges = goal['weightChangesSinceGoal'] ?? 0;
            goalAchievements[i] = {
              ...goal,
              'weightChangesSinceGoal': currentChanges + 1,
            };
            needsUpdate = true;
          }
        }
      }

      if (needsUpdate) {
        await achievementDoc.set({
          'goal_achievements': goalAchievements,
        }, SetOptions(merge: true));

        debugPrint("✅ Updated goal progress for $updateType");
      }
    } catch (e) {
      debugPrint('❌ Error updating goal progress: $e');
      // Don't rethrow to prevent breaking the weight update flow
    }
  }

  /// Show celebration floating window
  static Future<void> showGoalCelebrationDialog(
    BuildContext context,
    Map<String, dynamic> achievementData,
  ) async {
    debugPrint("🎊 _showGoalCelebrationDialog called!");

    final goalType = achievementData['goalType'];
    final initialWeight = achievementData['initialWeight'];
    final goalWeight = achievementData['goalWeight'];
    final achievedWeight = achievementData['achievedWeight'];
    final isMetric = achievementData['measurementSystem'] == 'Metric';
    final unit = isMetric ? 'kg' : 'lbs';

    debugPrint("🎯 Showing celebration for: $goalType");

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        debugPrint("✅ Celebration dialog builder called");
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.yellow.withOpacity(0.7),
              width: 3,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.celebration,
                color: Colors.yellow,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Goal Achieved! 🎉',
                style: TextStyle(
                  color: Colors.yellow,
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
              // Celebration icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.yellow,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Achievement message
              Text(
                'Congratulations! You have successfully reached your $goalType goal!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Progress details
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
                          'Starting Weight:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          '$initialWeight $unit',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Goal Weight:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          '$goalWeight $unit',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Achieved Weight:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          '$achievedWeight $unit',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Success message
              Text(
                'This amazing achievement has been recorded in your profile! Ready for your next challenge?',
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
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Show update goal dialog after celebration
                      _showUpdateGoalDialog(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.yellow.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Set New Goal',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close celebration dialog
                      // Navigate to profile page within the main screen (index 3 in bottom nav)
                      if (context.mounted) {
                        // Use GoRouter to navigate to profile route
                        context.go('/profile');
                        debugPrint(
                            "🎉 Navigating to profile page to show achievement");

                        // Force refresh the profile page to show new achievement
                        final userProvider = context.read<UserProvider>();
                        userProvider.notifyListeners();
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Celebrate!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  /// Show update goal floating window
  static Future<void> _showUpdateGoalDialog(BuildContext context) async {
    if (!context.mounted) return;

    await Future.delayed(
        Duration(milliseconds: 500)); // Small delay for better UX

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.blue.withOpacity(0.7),
              width: 3,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.flag,
                color: Colors.blue,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'New Goal?',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.trending_up,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Message
              const Text(
                'Would you like to set a new fitness goal to continue your amazing journey?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Benefits
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benefits of setting a new goal:',
                      style: TextStyle(
                        color: Colors.blue[200],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBenefitItem('Stay motivated and focused'),
                    _buildBenefitItem('Continue your progress'),
                    _buildBenefitItem('Achieve new milestones'),
                    _buildBenefitItem('Maintain healthy habits'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // This will trigger the edit goal functionality
                      _triggerEditGoalSheet(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Set New Goal',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Not Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  static Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Trigger edit goal sheet - integrated with the new widget
  static void _triggerEditGoalSheet(BuildContext context) {
    try {
      // Close any open dialogs first
      Navigator.of(context, rootNavigator: true).pop();

      // Use a small delay to ensure dialogs are closed
      Future.delayed(Duration(milliseconds: 300), () {
        // Show the EditGoalSheet widget
        showEditGoalSheet(context, onGoalUpdated: () {
          // Optional: Add any callback logic when goal is updated
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Goal updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        });
      });
    } catch (e) {
      debugPrint('Error triggering edit goal sheet: $e');
      // Fallback: Show instructions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Please go to User Profile → Update Goals to set a new goal'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Check if this is a new achievement
  static Future<bool> _isNewAchievement({
    required String userId,
    required String goalType,
    required double goalWeight,
  }) async {
    try {
      final achievementDoc = await FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId)
          .get();

      if (!achievementDoc.exists) {
        debugPrint('✅ First achievement for this user!');
        return true;
      }

      final achievementData = achievementDoc.data()!;
      final goalAchievements =
          achievementData['goal_achievements'] as List<dynamic>? ?? [];

      debugPrint('🔍 Checking existing achievements:');
      debugPrint('   - Total achievements found: ${goalAchievements.length}');
      debugPrint('   - Current goal: $goalType');
      debugPrint('   - Current goal weight: $goalWeight');

      // Check if this specific goal was already achieved
      bool alreadyAchieved = false;

      for (int i = 0; i < goalAchievements.length; i++) {
        final achievement = goalAchievements[i] as Map<String, dynamic>;
        final existingGoalType = achievement['goalType'] as String?;

        // FIX: Handle both int and double types for goalWeight
        final existingGoalWeightValue = achievement['goalWeight'];
        final existingGoalWeight = existingGoalWeightValue is int
            ? existingGoalWeightValue.toDouble()
            : existingGoalWeightValue as double?;

        final isAchieved = achievement['isAchieved'] == true;

        debugPrint(
            '   - Achievement $i: $existingGoalType, goal: $existingGoalWeight, achieved: $isAchieved');

        if (existingGoalType == goalType &&
            existingGoalWeight == goalWeight &&
            isAchieved) {
          alreadyAchieved = true;
          debugPrint(
              '❌ This exact goal achievement already exists and is achieved!');
          break;
        }
      }

      if (!alreadyAchieved) {
        debugPrint('✅ This is a new achievement or not yet achieved!');
      }

      return !alreadyAchieved;
    } catch (e) {
      debugPrint('❌ Error checking existing achievements: $e');
      return true; // If there's an error, assume it's new
    }
  }

  /// Mark goal as achieved in Firestore
  static Future<void> _markGoalAsAchieved({
    required String userId,
    required String goalType,
    required double goalWeight,
    required double achievedWeight,
  }) async {
    try {
      final achievementDoc = FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId);

      final achievementSnapshot = await achievementDoc.get();
      final currentData = achievementSnapshot.data() ?? {};
      final goalAchievements =
          currentData['goal_achievements'] as List<dynamic>? ?? [];

      // Find and update the specific goal
      for (int i = 0; i < goalAchievements.length; i++) {
        final achievement = goalAchievements[i] as Map<String, dynamic>;
        final existingGoalType = achievement['goalType'] as String?;

        // FIX: Handle both int and double types for goalWeight
        final existingGoalWeightValue = achievement['goalWeight'];
        final existingGoalWeight = existingGoalWeightValue is int
            ? existingGoalWeightValue.toDouble()
            : existingGoalWeightValue as double?;

        if (existingGoalType == goalType && existingGoalWeight == goalWeight) {
          // Update the achievement
          goalAchievements[i] = {
            ...achievement,
            'isAchieved': true,
            'achievedWeight': achievedWeight,
            'achievementDate': Timestamp.now(),
          };
          break;
        }
      }

      // Update the document
      await achievementDoc.set({
        'goal_achievements': goalAchievements,
      }, SetOptions(merge: true));

      debugPrint('✅ Goal marked as achieved successfully');
    } catch (e) {
      debugPrint('❌ Error marking goal as achieved: $e');
      rethrow;
    }
  }

  /// Record goal achievement in user_achievements collection
  static Future<void> recordGoalAchievement({
    required String userId,
    required Map<String, dynamic> achievementData,
  }) async {
    try {
      final achievementDoc = FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId);

      final achievementSnapshot = await achievementDoc.get();
      final currentData = achievementSnapshot.data() ?? {};
      final goalAchievements =
          currentData['goal_achievements'] as List<dynamic>? ?? [];

      // Add new achievement to the array with timestamp
      goalAchievements.add({
        ...achievementData,
        'achievementDate': Timestamp.now(),
      });

      // Update the document
      await achievementDoc.set({
        'goal_achievements': goalAchievements,
      }, SetOptions(merge: true));

      debugPrint('✅ Goal achievement recorded successfully');
    } catch (e) {
      debugPrint('❌ Error recording goal achievement: $e');
      rethrow;
    }
  }

  /// Update initial weight when goal is changed
  static Future<void> updateInitialWeightOnGoalChange({
    required String userId,
    required String userEmail,
    required double newWeight,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userEmail).set({
        'weight': newWeight,
      }, SetOptions(merge: true));

      debugPrint('✅ Initial weight updated for new goal: $newWeight');
    } catch (e) {
      debugPrint('❌ Error updating initial weight: $e');
      rethrow;
    }
  }
}
