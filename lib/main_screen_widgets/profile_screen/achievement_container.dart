import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class AchievementContainer extends StatelessWidget {
  const AchievementContainer({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: 150,
      width: screenWidth * 0.42,
      decoration: BoxDecoration(
        color: AppColors.containerBg,
        borderRadius: BorderRadius.circular(20),
      ),

    );
  }
}
