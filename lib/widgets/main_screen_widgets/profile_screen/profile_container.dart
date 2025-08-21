import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/statistics_container.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class ProfileContainer extends StatelessWidget {
  final String name;
  final int joinedDate;

  const ProfileContainer({
    super.key,
    required this.name,
    required this.joinedDate,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF262626),
              Color(0xFF413939),
              Color(0xFF363131),
              Color(0xFF302D2D),
              Color(0xFF886868),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: AppColors.titleText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Joined: $joinedDate',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),

          // Statistics Section
          const Text(
            'Statistics',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Days Streak
                const StatisticsContainer(
                  daysStreak: 30,
                  description: 'Day(s) Streak',
                ),
                const SizedBox(width: 10),
                // Highest Days Streak
                const StatisticsContainer(
                  daysStreak: 50,
                  description: 'Highest Streak',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
