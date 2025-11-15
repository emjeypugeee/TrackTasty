import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AchievementContainer extends StatelessWidget {
  final String title;
  final String description;
  final String nextStarDescription;
  final String progress;
  final int stars; // 1 to 5
  final bool isGoalAchievement;
  final String? goalType;
  final double? initialWeight;
  final double? achievedWeight;
  final DateTime? achievementDate;
  final String? unit;

  const AchievementContainer({
    super.key,
    required this.title,
    required this.description,
    required this.nextStarDescription,
    required this.progress,
    required this.stars,
    this.isGoalAchievement = false,
    this.goalType,
    this.initialWeight,
    this.achievedWeight,
    this.achievementDate,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // determine star color based on the number of stars
    Color getStarColor(int starCount) {
      switch (starCount) {
        case 5:
          return AppColors.fiveStarColor;
        case 4:
          return AppColors.fourStarColor;
        case 3:
          return AppColors.threeStarColor;
        case 2:
          return AppColors.twoStarColor;
        default:
          return AppColors.oneStarColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        minHeight:
            isGoalAchievement ? 180 : 160, // More height for goal achievements
      ),
      width: screenWidth * 0.42,
      decoration: BoxDecoration(
        color: AppColors.containerBg,
        borderRadius: BorderRadius.circular(20),
        border: isGoalAchievement
            ? Border.all(
                color: Colors.yellow,
                width: 2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and Goal Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isGoalAchievement)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.yellow,
                    size: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: index < stars ? getStarColor(stars) : Colors.grey,
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Goal Achievement Details
          if (isGoalAchievement && goalType != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Type
                Text(
                  'Goal: $goalType',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Weight Progress
                if (initialWeight != null && achievedWeight != null)
                  Text(
                    '${initialWeight!.toStringAsFixed(1)}$unit → ${achievedWeight!.toStringAsFixed(1)}$unit',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Achievement Date
                if (achievementDate != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(achievementDate!),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
              ],
            ),

          // Next Star Description (only for regular achievements)
          if (!isGoalAchievement)
            Text(
              nextStarDescription,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          // Spacer for layout
          if (!isGoalAchievement) const Spacer(),

          // Progress
          Text(
            isGoalAchievement ? 'Goal Completed' : 'Progress: $progress',
            style: TextStyle(
              color: isGoalAchievement ? Colors.yellow : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Completed badge for goal achievements
          if (isGoalAchievement)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                'COMPLETED',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
