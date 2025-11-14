import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/achievement_container.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/profile_container.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/goal_achievement_container.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Get user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
  }

  Future<void> refreshData() async {
    setState(() {});
  }

  // Get user achievements
  Future<Map<String, dynamic>> getUserAchievements() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return {};

    try {
      final doc = await FirebaseFirestore.instance
          .collection("user_achievements")
          .doc(currentUser.uid)
          .get();

      return doc.exists ? doc.data() ?? {} : {};
    } catch (e) {
      debugPrint("Error fetching achievements: $e");
      return {};
    }
  }

  // Get weight data
  Future<Map<String, dynamic>> getUserWeightData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return {
        'initialWeight': 0.0,
        'currentWeight': 0.0,
        'measurementSystem': 'Metric'
      };
    }

    try {
      // Get measurement system
      final userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser.email)
          .get();

      final measurementSystem =
          userDoc.data()?['measurementSystem'] ?? 'Metric';

      // Get all weight logs of the user
      final querySnapshot = await FirebaseFirestore.instance
          .collection("weight_history")
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('date', descending: false)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'initialWeight': 0.0,
          'currentWeight': 0.0,
          'measurementSystem': measurementSystem
        };
      }

      final initialWeight = querySnapshot.docs.first.data()['weight'];
      final currentWeight = querySnapshot.docs.last.data()['weight'];

      return {
        'initialWeight':
            (initialWeight is int ? initialWeight.toDouble() : initialWeight) ??
                0.0,
        'currentWeight':
            (currentWeight is int ? currentWeight.toDouble() : currentWeight) ??
                0.0,
        'measurementSystem': measurementSystem
      };
    } catch (e) {
      debugPrint("Error fetching weight data: $e");
      return {
        'initialWeight': 0.0,
        'currentWeight': 0.0,
        'measurementSystem': 'Metric'
      };
    }
  }

  // Get goal achievements - only return achieved goals
  Future<List<Map<String, dynamic>>> getGoalAchievements() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      final doc = await FirebaseFirestore.instance
          .collection("user_achievements")
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final goalAchievements =
            data['goal_achievements'] as List<dynamic>? ?? [];

        // Convert to List<Map<String, dynamic>>, filter only achieved goals, and sort by date (newest first)
        return goalAchievements
            .whereType<Map<String, dynamic>>()
            .where((achievement) =>
                achievement['isAchieved'] == true) // ONLY SHOW ACHIEVED GOALS
            .map((achievement) {
              final date = achievement['achievementDate'] is Timestamp
                  ? (achievement['achievementDate'] as Timestamp).toDate()
                  : DateTime.now();
              return {
                ...achievement,
                'achievementDate': date,
              };
            })
            .toList()
            .reversed
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching goal achievements: $e");
      return [];
    }
  }

  // Refresh all data
  Future<void> _refreshData(BuildContext context) async {
    debugPrint("🔄 Refreshing profile data...");

    // Force refresh by triggering rebuild
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.notifyListeners();

    // Add a small delay to ensure data is reloaded
    await Future.delayed(Duration(milliseconds: 500));

    // Force rebuild of this widget
    if (mounted) {
      setState(() {});
    }

    debugPrint("✅ Profile data refreshed");
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refreshData(context),
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: getUserDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (FirebaseAuth.instance.currentUser == null) {
              return Center(child: Text("Please log in to view profile"));
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error loading profile"));
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data();
              String username = userData?['username'] ?? "Unknown User";
              final joinedDateRaw = userData?['dateAccountCreated'];
              DateTime joinedDate;
              if (joinedDateRaw is int && joinedDateRaw > 1000000000000) {
                // If it's a timestamp (milliseconds since epoch)
                joinedDate = DateTime.fromMillisecondsSinceEpoch(joinedDateRaw);
              } else if (joinedDateRaw is int) {
                // If it's a simple year or date
                joinedDate = DateTime(joinedDateRaw);
              } else {
                joinedDate = DateTime.now();
              }
              int dayStreak;
              int highestDayStreak;

              return FutureBuilder<Map<String, dynamic>>(
                  future: getUserAchievements(),
                  builder: (context, achievementSnapshot) {
                    if (achievementSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final achievements = achievementSnapshot.data ?? {};
                    dayStreak = achievements['daily_streak'] ?? 0;
                    highestDayStreak = achievements['highest_streak'] ?? 0;

                    return FutureBuilder<Map<String, dynamic>>(
                      future: getUserWeightData(),
                      builder: (context, weightSnapshot) {
                        if (weightSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final weightData = weightSnapshot.data ??
                            {
                              'initialWeight': 0.0,
                              'currentWeight': 0.0,
                              'measurementSystem': 'Metric'
                            };
                        final double initialWeight =
                            (weightData['initialWeight'] as num).toDouble();
                        final double currentWeight =
                            (weightData['currentWeight'] as num).toDouble();
                        final String measurementSystem =
                            weightData['measurementSystem'] ?? 'Metric';

                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: getGoalAchievements(),
                          builder: (context, goalAchievementSnapshot) {
                            if (goalAchievementSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final goalAchievements =
                                goalAchievementSnapshot.data ?? [];

                            // ACHIEVEMENT DATA
                            final List<Map<String, dynamic>>
                                regularAchievements = [
                              {
                                'id': 'daily_tracker',
                                'title': 'Daily Tracker',
                                'description':
                                    'Reached a ${_getAchievementLevel(achievements['highest_streak'] ?? 0, [
                                      7,
                                      14,
                                      60,
                                      180,
                                      365
                                    ])} days streak!',
                                'nextStarDescription': _getNextStarDescription(
                                    achievements['highest_streak'] ?? 0,
                                    [7, 14, 60, 180, 365],
                                    'days streak'),
                                'progress':
                                    '${achievements['highest_streak'] ?? 0} days',
                                'stars': _getStarCount(
                                    achievements['highest_streak'] ?? 0,
                                    [7, 14, 60, 180, 365]),
                              },
                              {
                                'id': 'click_eat',
                                'title': 'Click & Eat',
                                'description':
                                    'Used image logging ${_getAchievementLevel(achievements['image_logs'] ?? 0, [
                                      10,
                                      30,
                                      50,
                                      100,
                                      200
                                    ])} times.',
                                'nextStarDescription': _getNextStarDescription(
                                    achievements['image_logs'] ?? 0,
                                    [10, 30, 50, 100, 200],
                                    'image logs'),
                                'progress':
                                    '${achievements['image_logs'] ?? 0} times',
                                'stars': _getStarCount(
                                    achievements['image_logs'] ?? 0,
                                    [10, 30, 50, 100, 200]),
                              },
                              {
                                'id': 'food_explorer',
                                'title': 'Food Explorer',
                                'description':
                                    'Logged ${_getAchievementLevel(achievements['unique_foods'] ?? 0, [
                                      20,
                                      50,
                                      100,
                                      150,
                                      250
                                    ])} unique foods.',
                                'nextStarDescription': _getNextStarDescription(
                                    achievements['unique_foods'] ?? 0,
                                    [20, 50, 100, 150, 250],
                                    'unique foods'),
                                'progress':
                                    '${achievements['unique_foods'] ?? 0} foods',
                                'stars': _getStarCount(
                                    achievements['unique_foods'] ?? 0,
                                    [20, 50, 100, 150, 250]),
                              },
                              {
                                'id': 'macro_magician',
                                'title': 'Macro Magician',
                                'description':
                                    'Hit all 3 macro targets ${_getAchievementLevel(achievements['macro_perfect_days'] ?? 0, [
                                      7,
                                      14,
                                      60,
                                      180,
                                      365
                                    ])} times.',
                                'nextStarDescription': _getNextStarDescription(
                                    achievements['macro_perfect_days'] ?? 0,
                                    [7, 14, 60, 180, 365],
                                    'perfect days'),
                                'progress':
                                    '${achievements['macro_perfect_days'] ?? 0} days',
                                'stars': _getStarCount(
                                    achievements['macro_perfect_days'] ?? 0,
                                    [7, 14, 60, 180, 365]),
                              },
                            ];

                            return SingleChildScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: EdgeInsets.all(0),
                                child: Column(
                                  children: [
                                    ProfileContainer(
                                      name: username,
                                      joinedDate: joinedDate,
                                      dayStreak: dayStreak,
                                      highestDayStreak: highestDayStreak,
                                      initialWeight: initialWeight,
                                      currentWeight: currentWeight,
                                      measurementSystem: measurementSystem,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Goal Achievements Section
                                          if (goalAchievements.isNotEmpty) ...[
                                            Text(
                                              'Goal Achievements',
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  goalAchievements.length,
                                              itemBuilder: (context, index) {
                                                final achievement =
                                                    goalAchievements[index];
                                                final goalType =
                                                    achievement['goalType'] ??
                                                        'Unknown Goal';
                                                final initialWeight =
                                                    (achievement[
                                                                'initialWeight']
                                                            as num)
                                                        .toDouble();
                                                final achievedWeight =
                                                    (achievement[
                                                                'achievedWeight']
                                                            as num)
                                                        .toDouble();
                                                final achievementDate = achievement[
                                                            'achievementDate']
                                                        is DateTime
                                                    ? achievement[
                                                            'achievementDate']
                                                        as DateTime
                                                    : DateTime.now();
                                                final isMetric = achievement[
                                                        'measurementSystem'] ==
                                                    'Metric';
                                                final unit =
                                                    isMetric ? 'kg' : 'lbs';

                                                return GoalAchievementContainer(
                                                  title: 'Goal: $goalType',
                                                  description:
                                                      'Successfully achieved your $goalType goal',
                                                  goalType: goalType,
                                                  initialWeight: initialWeight,
                                                  achievedWeight:
                                                      achievedWeight,
                                                  achievementDate:
                                                      achievementDate,
                                                  unit: unit,
                                                );
                                              },
                                            ),
                                            SizedBox(height: 24),
                                          ],

                                          // Regular Achievements Section
                                          Text(
                                            'Regular Achievements',
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 1,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 1.8,
                                            ),
                                            itemCount:
                                                regularAchievements.length,
                                            itemBuilder: (context, index) {
                                              final achievement =
                                                  regularAchievements[index];
                                              return AchievementContainer(
                                                title: achievement['title'],
                                                description:
                                                    achievement['description'],
                                                nextStarDescription:
                                                    achievement[
                                                        'nextStarDescription'],
                                                progress:
                                                    achievement['progress'],
                                                stars: achievement['stars'],
                                                isGoalAchievement: false,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  });
            }

            // Return if no user found
            return Center(child: Text("User not found"));
          },
        ),
      ),
    );
  }

  // Get star count based on progress
  int _getStarCount(int progress, List<int> milestones) {
    for (int i = milestones.length - 1; i >= 0; i--) {
      if (progress >= milestones[i]) {
        return i + 1;
      }
    }
    return 0;
  }

  // Get achievement level description
  String _getAchievementLevel(int progress, List<int> milestones) {
    for (int i = milestones.length - 1; i >= 0; i--) {
      if (progress >= milestones[i]) {
        return milestones[i].toString();
      }
    }
    return progress.toString();
  }

  // Get next star description
  String _getNextStarDescription(
      int progress, List<int> milestones, String unit) {
    for (int i = 0; i < milestones.length; i++) {
      if (progress < milestones[i]) {
        final needed = milestones[i] - progress;
        return 'Need more $needed $unit for next star';
      }
    }
    return 'Max level reached!';
  }
}
