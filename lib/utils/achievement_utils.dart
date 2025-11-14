import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/utils/goal_achievement_utils.dart';
import 'package:flutter/material.dart';

class AchievementUtils {
  static Future<void> updateAchievementsOnFoodLog({
    required String userId,
    required Map<String, dynamic> foodLogData,
    required String newMealName,
    required bool isImageLog,
    required BuildContext context,
  }) async {
    try {
      final achievementDoc = FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId);

      final achievementSnapshot = await achievementDoc.get();
      final achievementData = achievementSnapshot.data() ?? {};

      // Check if this is a new food
      final bool isNewFood = await _isNewFood(userId, newMealName);

      // Track achievements earned
      List<String> achievementsEarned = [];

      // Update unique foods count if it's a new food
      if (isNewFood) {
        final uniqueFoods = achievementData['unique_foods'] ?? 0;
        await achievementDoc.set(
          {'unique_foods': uniqueFoods + 1},
          SetOptions(merge: true),
        );
        achievementsEarned.add('New food discovered!');
        debugPrint(
            'New food detected: $newMealName - unique foods count updated');
      }

      // Update image logs count if it's an image log
      if (isImageLog) {
        final imageLogs = achievementData['image_logs'] ?? 0;
        await achievementDoc.set(
          {'image_logs': imageLogs + 1},
          SetOptions(merge: true),
        );
        achievementsEarned.add('Image log recorded!');
        debugPrint('Image log recorded');
      }

      // Update daily streak and highest streak
      final streakUpdate = await _updateDailyStreak(
          userId, achievementDoc, achievementData, context);
      if (streakUpdate.isNotEmpty) {
        achievementsEarned.add(streakUpdate);
      }

      // Check if macros are perfect
      final macroPerfect = await _checkMacroPerfectDays(
          userId, achievementDoc, achievementData, foodLogData);
      debugPrint("Macro Perfect Status: $macroPerfect");
      if (macroPerfect) {
        achievementsEarned.add('Perfect macro day!');
      }

      // Show SnackBar with achievements earned
      if (achievementsEarned.isNotEmpty) {
        /*WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Achievements earned:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  ...achievementsEarned
                      .map((achievement) => Text('• $achievement'))
                      .toList(),
                ],
              ),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green[700],
            ),
          );
        });*/
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {});
      }
    } catch (e) {
      debugPrint('Error updating achievements: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating achievements: $e'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  static Future<bool> _isNewFood(String userId, String mealName) async {
    try {
      // Query all food logs for this user to check if this meal was ever logged before
      final foodLogsSnapshot = await FirebaseFirestore.instance
          .collection('food_logs')
          .where('userId', isEqualTo: userId)
          .get();

      // Check all food logs for this meal name (excluding the current session)
      for (final doc in foodLogsSnapshot.docs) {
        final foodLogData = doc.data();
        final foods = foodLogData['foods'] as List<dynamic>? ?? [];

        for (final food in foods) {
          final existingMealName = food['mealName'] as String?;
          final loggedTime = food['loggedTime'] as Timestamp?;

          // Check if this food was logged BEFORE the current session
          if (existingMealName?.toLowerCase() == mealName.toLowerCase() &&
              loggedTime != null &&
              loggedTime
                  .toDate()
                  .isBefore(DateTime.now().subtract(Duration(minutes: 1)))) {
            debugPrint(
                'Food "$mealName" already exists in user\'s history (logged at ${loggedTime.toDate()})');
            return false; // Food already exists in previous logs
          }
        }
      }

      debugPrint('Food "$mealName" is new for this user');
      return true; // Food is new
    } catch (e) {
      debugPrint('Error checking if food is new: $e');
      return false; // Assume not new on error
    }
  }

  static Future<String> _updateDailyStreak(
    String userId,
    DocumentReference achievementDoc,
    Map<String, dynamic> achievementData,
    BuildContext context,
  ) async {
    final lastLoggedDate = achievementData['last_logged_date'];
    final currentStreak = achievementData['daily_streak'] ?? 0;
    final highestStreak = achievementData['highest_streak'] ?? 0;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    debugPrint('Checking daily streak...');
    debugPrint('Last logged date: $lastLoggedDate');
    debugPrint('Current streak: $currentStreak');
    debugPrint('Highest streak: $highestStreak');

    String streakUpdate = '';

    if (lastLoggedDate == null) {
      // First time logging - start streak at 1
      final newStreak = 1;
      final newHighestStreak =
          newStreak > highestStreak ? newStreak : highestStreak;

      await achievementDoc.set({
        'daily_streak': newStreak,
        'highest_streak': newHighestStreak,
        'last_logged_date': Timestamp.fromDate(today)
      }, SetOptions(merge: true));

      await GoalAchievementUtils.updateGoalProgress(
        userId: userId,
        updateType: 'food_log',
      );

      debugPrint('First food log - streak started: $newStreak');
      streakUpdate = 'Daily streak started!';

      // Show celebration for first streak immediately
      showStreakCelebrationDialog(context, newStreak);
    } else {
      final lastDate = (lastLoggedDate as Timestamp).toDate();

      // Check if already logged today
      if (lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day) {
        debugPrint('Already logged today - streak unchanged: $currentStreak');
        streakUpdate = '';
      }
      // Check if logged yesterday (continuing streak)
      else if (lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day) {
        final newStreak = currentStreak + 1;
        final newHighestStreak =
            newStreak > highestStreak ? newStreak : highestStreak;

        await achievementDoc.set({
          'daily_streak': newStreak,
          'highest_streak': newHighestStreak,
          'last_logged_date': Timestamp.fromDate(today)
        }, SetOptions(merge: true));

        await GoalAchievementUtils.updateGoalProgress(
          userId: userId,
          updateType: 'food_log',
        );

        debugPrint('Streak continued: $newStreak days');
        streakUpdate = 'Daily streak: $newStreak days!';

        // Always show celebration when streak increases (first log today)
        debugPrint('🎉 Streak increased to: $newStreak days');

        showStreakCelebrationDialog(context, newStreak);
      }
      // Streak broken (missed one or more days)
      else {
        final newStreak = 1;
        final newHighestStreak = highestStreak;

        await achievementDoc.set({
          'daily_streak': newStreak,
          'highest_streak': newHighestStreak,
          'last_logged_date': Timestamp.fromDate(today)
        }, SetOptions(merge: true));

        await GoalAchievementUtils.updateGoalProgress(
          userId: userId,
          updateType: 'food_log',
        );

        debugPrint('Streak broken - reset to 1');
        streakUpdate = 'New streak started!';
        showStreakCelebrationDialog(context, newStreak);
      }
    }

    return streakUpdate;
  }

  static Future<void> showStreakCelebrationDialog(
    BuildContext context,
    int streakDays,
  ) async {
    debugPrint(
        '🎊 showStreakCelebrationDialog called! Streak: $streakDays days');

    if (!context.mounted) {
      debugPrint('❌ Context is not mounted. Cannot show dialog.');
      return;
    }

    final celebrationMessage = _getStreakCelebrationMessage(streakDays);
    final milestoneTitle = _getMilestoneTitle(streakDays);
    final streakColor = _getStreakColor(streakDays);

    // Delay showing the dialog to ensure the bottom sheet is completely closed
    Future.delayed(Duration(milliseconds: 100), () {
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          debugPrint('🎉 Displaying streak celebration dialog...');
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: streakColor.withOpacity(0.7),
                width: 3,
              ),
            ),
            title: Center(
              child: Text(
                milestoneTitle,
                style: TextStyle(
                  color: streakColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
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
                      color: streakColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStreakIcon(streakDays),
                      size: 60,
                      color: streakColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Achievement message
                Text(
                  celebrationMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Streak details
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
                            'Current Streak:',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            '$streakDays days',
                            style: TextStyle(
                              color: streakColor,
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
                            'Milestone:',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            _getMilestoneDescription(streakDays),
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
                            'Status:',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            _getStreakStatus(streakDays),
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

                // Motivational tip
                Text(
                  _getMotivationalTip(streakDays),
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
                  const Expanded(
                    child: SizedBox.shrink(),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        debugPrint('🎉 Streak celebration dialog dismissed.');
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
                      child: const Text(
                        'Keep Going!',
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
    });
  }

  /// Helper method to get milestone description
  static String _getMilestoneDescription(int streakDays) {
    if (streakDays == 1) return 'First Day';
    if (streakDays == 7) return 'One Week';
    if (streakDays == 30) return 'One Month';
    if (streakDays == 60) return 'Two Months';
    if (streakDays == 90) return 'Three Months';
    if (streakDays == 100) return '100 Days';
    if (streakDays % 100 == 0) return '${streakDays ~/ 100}00 Days';
    if (streakDays % 50 == 0) return '${streakDays} Days';
    return 'Amazing Progress';
  }

  /// Helper method to get streak status
  static String _getStreakStatus(int streakDays) {
    if (streakDays == 1) return 'Getting Started';
    if (streakDays <= 7) return 'Building Habit';
    if (streakDays <= 30) return 'Consistent';
    if (streakDays <= 90) return 'Dedicated';
    return 'Unstoppable';
  }

  /// Get randomized celebration message based on streak days
  static String _getStreakCelebrationMessage(int streakDays) {
    final messages = <String>[];

    if (streakDays == 1) {
      messages.addAll([
        'Amazing start! Your fitness journey begins now! 🚀',
        'First day down, many more to go! You\'ve got this! 💪',
        'The first step is always the hardest - great job starting! 🌟'
      ]);
    } else if (streakDays == 7) {
      messages.addAll([
        'One week strong! You\'re building incredible habits! 📈',
        '7 days of consistency! You\'re officially unstoppable! 🔥',
        'A whole week! Your dedication is truly inspiring! ✨'
      ]);
    } else if (streakDays == 30) {
      messages.addAll([
        'One month of dedication! You\'re a tracking superstar! 🌙',
        '30 days strong! Your commitment is paying off! 🏆',
        'A full month! You\'ve turned tracking into a lifestyle! 💫'
      ]);
    } else if (streakDays == 60) {
      messages.addAll([
        'Two months of consistency! You\'re building legendary habits! ⚡',
        '60 days strong! Your perseverance is incredible! 🌟',
        'Two months down! You\'re mastering your nutrition! 🥇'
      ]);
    } else if (streakDays == 90) {
      messages.addAll([
        'Three months! You\'ve achieved what most only dream of! 🏅',
        '90 days of excellence! You\'re a tracking champion! 💎',
        'Quarter year strong! Your transformation is amazing! 🔥'
      ]);
    } else if (streakDays == 100) {
      messages.addAll([
        '100 days! You\'ve reached elite status! 💯',
        'Century streak! Your dedication is absolutely phenomenal! 🌈',
        '100 days strong! You\'re an inspiration to everyone! 🚀'
      ]);
    } else if (streakDays % 50 == 0) {
      messages.addAll([
        '$streakDays days! You\'re on an incredible journey! 🌟',
        '$streakDays days strong! Your consistency is remarkable! 💪',
        '$streakDays days of tracking! You\'re achieving greatness! ✨'
      ]);
    } else {
      // Generic messages for other milestones
      messages.addAll([
        '$streakDays days strong! Keep up the amazing work! 🔥',
        'Incredible! $streakDays days of consistent tracking! 🌟',
        'Your $streakDays-day streak is absolutely inspiring! 💫'
      ]);
    }

    // Return random message
    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }

  /// Get milestone title based on streak days
  static String _getMilestoneTitle(int streakDays) {
    if (streakDays == 1) return 'Streak Started! 🎉';
    if (streakDays == 7) return 'Weekly Warrior! 🏆';
    if (streakDays == 30) return 'Monthly Master! 🌙';
    if (streakDays == 60) return 'Two-Month Titan! ⚡';
    if (streakDays == 90) return 'Quarter Champion! 💎';
    if (streakDays == 100) return 'Century Club! 💯';
    if (streakDays % 100 == 0) return '${streakDays ~/ 100}00 Days! 🎊';
    if (streakDays % 50 == 0) return '${streakDays} Days! ✨';

    return 'Streak Milestone! 🎉';
  }

  /// Get color based on streak length
  static Color _getStreakColor(int streakDays) {
    if (streakDays == 1) return Colors.blue;
    if (streakDays <= 7) return Colors.green;
    if (streakDays <= 30) return Colors.orange;
    if (streakDays <= 90) return Colors.red;
    return Colors.purple;
  }

  /// Get icon based on streak length
  static IconData _getStreakIcon(int streakDays) {
    if (streakDays == 1) return Icons.flag;
    if (streakDays <= 7) return Icons.local_fire_department;
    if (streakDays <= 30) return Icons.emoji_events;
    if (streakDays <= 90) return Icons.workspace_premium;
    return Icons.auto_awesome;
  }

  /// Get motivational tip based on streak
  static String _getMotivationalTip(int streakDays) {
    if (streakDays == 1) {
      return 'Tip: Try to log at the same time each day to build a strong habit.';
    } else if (streakDays <= 7) {
      return 'Tip: Consistency beats perfection. Keep showing up every day!';
    } else if (streakDays <= 30) {
      return 'Tip: Review your weekly progress to see how far you\'ve come.';
    } else {
      return 'Tip: You\'ve built a powerful habit. Consider setting new challenges!';
    }
  }

  static Future<bool> _checkMacroPerfectDays(
    String userId,
    DocumentReference achievementDoc,
    Map<String, dynamic> achievementData,
    Map<String, dynamic> foodLogData,
  ) async {
    try {
      debugPrint("CHECKING FOR PERFECT MACRO DAY");
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        debugPrint('No user logged in or email is null');
        return false;
      }

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user?.email)
          .get();

      if (!doc.exists) {
        debugPrint('User document not found for userId: $userId');
        return false;
      }

      final userData = doc.data();

      if (userData == null) {
        debugPrint('User data is null');
        return false;
      }
      final targetCalories = userData['dailyCalories'] ?? 2000;
      final targetProtein = userData['proteinGram'] ?? 150;
      final targetCarbs = userData['carbsGram'] ?? 200;
      final targetFat = userData['fatsGram'] ?? 70;

      final totalCalories = foodLogData['totalCalories'] ?? 0;
      final totalProtein = foodLogData['totalProtein'] ?? 0;
      final totalCarbs = foodLogData['totalCarbs'] ?? 0;
      final totalFat = foodLogData['totalFat'] ?? 0;

      debugPrint(
          'Targets - Calories: $targetCalories, Protein: $targetProtein, Carbs: $targetCarbs, Fat: $targetFat');
      debugPrint(
          'Current - Calories: $totalCalories, Protein: $totalProtein, Carbs: $totalCarbs, Fat: $totalFat');

      // Check if all macros reached at least 100% of targets
      final caloriesPerfect = totalCalories >= targetCalories;
      debugPrint("Perfect Macro Day for Calories Status: $caloriesPerfect");
      final proteinPerfect = totalProtein >= targetProtein;
      debugPrint("Perfect Macro Day for Protein Status: $proteinPerfect");
      final carbsPerfect = totalCarbs >= targetCarbs;
      debugPrint("Perfect Macro Day for Carbs Status: $carbsPerfect");
      final fatPerfect = totalFat >= targetFat;
      debugPrint("Perfect Macro Day for Fats Status: $fatPerfect");

      if (caloriesPerfect && proteinPerfect && carbsPerfect && fatPerfect) {
        // Update macro perfect days
        final macroPerfectDays = achievementData['macro_perfect_days'] ?? 0;

        // Check if user already has a macro perfect day today
        final lastPerfectDate = achievementData['last_perfect_date'];
        final today = DateTime.now();

        if (lastPerfectDate == null ||
            (lastPerfectDate as Timestamp).toDate().day != today.day) {
          // First perfect day today
          await achievementDoc.set({
            'macro_perfect_days': macroPerfectDays + 1,
            'last_perfect_date': Timestamp.fromDate(today)
          }, SetOptions(merge: true));
          debugPrint(
              'Perfect macro day achieved! Total: ${macroPerfectDays + 1}');
          return true;
        } else {
          debugPrint('Perfect macro day already recorded today');
          return false;
        }
      } else {
        debugPrint(
            'Macros not perfect - calories: $caloriesPerfect ($totalCalories/$targetCalories), protein: $proteinPerfect ($totalProtein/$targetProtein), carbs: $carbsPerfect ($totalCarbs/$targetCarbs), fat: $fatPerfect ($totalFat/$targetFat)');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking macro perfect days: $e');
      return false;
    }
  }
}
