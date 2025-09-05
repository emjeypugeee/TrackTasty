import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/achievement_container.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/profile_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import

final GlobalKey<_ProfilePageState> ProfilePageKey = GlobalKey<_ProfilePageState>();

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> _achievements = {};
  bool _isLoadingAchievements = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("user_achievements")
          .doc(currentUser.uid)
          .get();

      setState(() {
        _achievements = doc.exists ? doc.data() ?? {} : {};
        _isLoadingAchievements = false;
      });
    } catch (e) {
      debugPrint("Error fetching achievements: $e");
      setState(() {
        _isLoadingAchievements = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context); // Listen to provider

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(0),
          child: Column(
            children: [
              ProfileContainer(
                name: userProvider.nickname, // Use provider data
                joinedDate: userProvider.joinedDate ?? 0, // Add this to your provider
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        'Achievements',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _isLoadingAchievements
                          ? Center(child: CircularProgressIndicator())
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.5,
                              ),
                              itemCount: _achievementList.length,
                              itemBuilder: (context, index) {
                                final achievement = _achievementList[index];
                                return AchievementContainer(
                                  title: achievement['title'],
                                  description: achievement['description'],
                                  nextStarDescription:
                                      achievement['nextStarDescription'],
                                  progress: achievement['progress'],
                                  stars: achievement['stars'],
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _achievementList {
    return [
      {
        'id': 'daily_tracker',
        'title': 'Daily Tracker',
        'description':
            'Reached a ${_getAchievementLevel(_achievements['daily_streak'] ?? 0, [7, 14, 60, 180, 365])} days streak!',
        'nextStarDescription': _getNextStarDescription(
            _achievements['daily_streak'] ?? 0, [7, 14, 60, 180, 365], 'days streak'),
        'progress': '${_achievements['daily_streak'] ?? 0} days',
        'stars': _getStarCount(_achievements['daily_streak'] ?? 0, [7, 14, 60, 180, 365]),
      },
      {
        'id': 'click_eat',
        'title': 'Click & Eat',
        'description':
            'Used image logging ${_getAchievementLevel(_achievements['image_logs'] ?? 0, [10, 30, 50, 100, 200])} times.',
        'nextStarDescription': _getNextStarDescription(
            _achievements['image_logs'] ?? 0, [10, 30, 50, 100, 200], 'image logs'),
        'progress': '${_achievements['image_logs'] ?? 0} times',
        'stars': _getStarCount(_achievements['image_logs'] ?? 0, [10, 30, 50, 100, 200]),
      },
      {
        'id': 'food_explorer',
        'title': 'Food Explorer',
        'description':
            'Logged ${_getAchievementLevel(_achievements['unique_foods'] ?? 0, [20, 50, 100, 150, 250])} unique foods.',
        'nextStarDescription': _getNextStarDescription(
            _achievements['unique_foods'] ?? 0, [20, 50, 100, 150, 250], 'unique foods'),
        'progress': '${_achievements['unique_foods'] ?? 0} foods',
        'stars': _getStarCount(_achievements['unique_foods'] ?? 0, [20, 50, 100, 150, 250]),
      },
      {
        'id': 'macro_magician',
        'title': 'Macro Magician',
        'description':
            'Hit all 3 macro targets ${_getAchievementLevel(_achievements['macro_perfect_days'] ?? 0, [7, 14, 60, 180, 365])} times.',
        'nextStarDescription': _getNextStarDescription(
            _achievements['macro_perfect_days'] ?? 0, [7, 14, 60, 180, 365], 'perfect days'),
        'progress': '${_achievements['macro_perfect_days'] ?? 0} days',
        'stars': _getStarCount(
            _achievements['macro_perfect_days'] ?? 0, [7, 14, 60, 180, 365]),
      },
    ];
  }

  // Helper function to get star count based on progress
  int _getStarCount(int progress, List<int> milestones) {
    for (int i = milestones.length - 1; i >= 0; i--) {
      if (progress >= milestones[i]) {
        return i + 1;
      }
    }
    return 0;
  }

  // Helper function to get achievement level description
  String _getAchievementLevel(int progress, List<int> milestones) {
    for (int i = milestones.length - 1; i >= 0; i--) {
      if (progress >= milestones[i]) {
        return milestones[i].toString();
      }
    }
    return progress.toString();
  }

  // Helper function to get next star description
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