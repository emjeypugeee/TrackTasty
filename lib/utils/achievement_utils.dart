import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

      // Update daily streak
      final streakUpdate =
          await _updateDailyStreak(achievementDoc, achievementData);
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Food logged successfully!'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.blue[700],
            ),
          );
        });
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
    DocumentReference achievementDoc,
    Map<String, dynamic> achievementData,
  ) async {
    final lastLoggedDate = achievementData['last_logged_date'];
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (lastLoggedDate == null) {
      // First time logging
      await achievementDoc.set(
          {'daily_streak': 1, 'last_logged_date': Timestamp.fromDate(today)},
          SetOptions(merge: true));
      debugPrint('First food log - streak started');
      return 'Daily streak started!';
    } else {
      final lastDate = (lastLoggedDate as Timestamp).toDate();
      if (lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day) {
        // Already logged today, no change to streak
        debugPrint('Already logged today - streak unchanged');
        return '';
      } else if (lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day) {
        // Logged yesterday, continue streak
        final currentStreak = achievementData['daily_streak'] ?? 0;
        await achievementDoc.set({
          'daily_streak': currentStreak + 1,
          'last_logged_date': Timestamp.fromDate(today)
        }, SetOptions(merge: true));
        debugPrint('Streak continued: ${currentStreak + 1} days');
        return 'Daily streak: ${currentStreak + 1} days!';
      } else {
        // Broken streak, reset to 1
        await achievementDoc.set(
            {'daily_streak': 1, 'last_logged_date': Timestamp.fromDate(today)},
            SetOptions(merge: true));
        debugPrint('Streak broken - reset to 1 day');
        return 'New streak started!';
      }
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
