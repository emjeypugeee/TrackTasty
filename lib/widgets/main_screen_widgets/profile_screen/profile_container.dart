import 'package:fitness/widgets/main_screen_widgets/profile_screen/statistics_container.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileContainer extends StatelessWidget {
  final String name;
  final DateTime joinedDate;
  final int dayStreak;
  final int highestDayStreak;
  final double initialWeight;
  final double currentWeight;
  final String measurementSystem;

  const ProfileContainer({
    super.key,
    required this.name,
    required this.joinedDate,
    required this.dayStreak,
    required this.highestDayStreak,
    required this.initialWeight,
    required this.currentWeight,
    required this.measurementSystem,
  });

  // Convert kg to lbs for US system
  double _convertToPounds(double kg) {
    return kg * 2.20462;
  }

  // Format weight based on measurement system
  String _formatWeight(double weight, String system) {
    if (system == 'US') {
      return _convertToPounds(weight).toStringAsFixed(1);
    }
    return weight.toStringAsFixed(1);
  }

  // Get weight unit based on measurement system
  String _getWeightUnit(String system) {
    return system == 'US' ? 'lbs' : 'kg';
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Format the joined date
    final formattedJoinedDate = DateFormat('MMMM dd, yyyy').format(joinedDate);

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
            'Joined: $formattedJoinedDate',
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
                StatisticsContainer(
                  value: dayStreak,
                  description: 'Day(s) Streak',
                  isWeight: false,
                ),
                const SizedBox(width: 10),
                // Highest Days Streak
                StatisticsContainer(
                  value: highestDayStreak,
                  description: 'Highest Streak',
                  isWeight: false,
                ),
                const SizedBox(width: 10),
                // Initial Weight
                StatisticsContainer(
                  value: double.parse(
                      _formatWeight(initialWeight, measurementSystem)),
                  description:
                      'Initial Weight (${_getWeightUnit(measurementSystem)})',
                  isWeight: true,
                ),
                const SizedBox(width: 10),
                // Current Weight
                StatisticsContainer(
                  value: double.parse(
                      _formatWeight(currentWeight, measurementSystem)),
                  description:
                      'Current Weight (${_getWeightUnit(measurementSystem)})',
                  isWeight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
