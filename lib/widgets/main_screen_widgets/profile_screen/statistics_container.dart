import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class StatisticsContainer extends StatelessWidget {
  final num value;
  final String description;
  final bool isWeight;

  const StatisticsContainer({
    super.key,
    required this.value,
    required this.description,
    required this.isWeight,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 80,
      width: (screenWidth - 60) / 1.5,
      decoration: BoxDecoration(
        color: AppColors.containerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Icon(
            isWeight
                ? Icons.scale_outlined
                : Icons.local_fire_department_rounded,
            size: 50,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWeight ? value.toStringAsFixed(1) : '$value',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
