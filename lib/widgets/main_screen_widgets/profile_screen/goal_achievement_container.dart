import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoalAchievementContainer extends StatelessWidget {
  final String title;
  final String description;
  final String goalType;
  final double initialWeight;
  final double achievedWeight;
  final DateTime achievementDate;
  final String unit;

  const GoalAchievementContainer({
    super.key,
    required this.title,
    required this.description,
    required this.goalType,
    required this.initialWeight,
    required this.achievedWeight,
    required this.achievementDate,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Remove fixed height and let content determine the size
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[800]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.yellow, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'From ${initialWeight.toStringAsFixed(1)}$unit to ${achievedWeight.toStringAsFixed(1)}$unit',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Achieved on ${DateFormat('MMM dd, yyyy').format(achievementDate)}',
                  style: TextStyle(
                    color: Colors.green[200],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
