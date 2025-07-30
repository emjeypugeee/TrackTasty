import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class StatisticsContainer extends StatelessWidget {
  const StatisticsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 80,
      width: screenWidth * 0.42,
      decoration: BoxDecoration(
        color: AppColors.containerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            size: 50,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '30',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              const Text(
                'Day(s) Streak',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
