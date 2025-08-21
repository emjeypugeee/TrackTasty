import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class AchievementContainer extends StatelessWidget {
  final String title;
  final String description;
  final String nextStarDescription;
  final String progress;
  final int stars; // 1 to 5
  const AchievementContainer(
      {super.key,
      required this.title,
      required this.description,
      required this.nextStarDescription,
      required this.progress,
      required this.stars});

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
      constraints: const BoxConstraints(
        minHeight: 160, // Minimum height instead of fixed height
      ),
      width: screenWidth * 0.42,
      decoration: BoxDecoration(
        color: AppColors.containerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

          // Next Star Description
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
          const Spacer(),

          // Progress
          Text(
            'Progress: $progress',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
