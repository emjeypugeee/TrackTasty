import 'package:flutter/material.dart';
import 'package:fitness/theme/app_color.dart';

class AboutUsWidget extends StatelessWidget {
  const AboutUsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Center(
            child: Text(
              'About Us',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(
            color: AppColors.primaryText.withOpacity(0.3),
            thickness: 1,
          ),
          const SizedBox(height: 20),

          // Mission Section
          Text(
            'OUR MISSION',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To empower individuals to live healthier lives by making food tracking simple, smart, and supportive through innovative technology and a caring community.',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),

          // Vision Section
          Text(
            'OUR VISION',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To become the essential wellness companion that helps people build lasting healthy habits — one meal, one step, one goal at a time.',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),

          // Closing statement
          Center(
            child: Text(
              'Join us on this journey to better health!',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
