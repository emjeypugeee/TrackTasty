import 'package:fitness/theme/app_color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LinegraphStatistics extends StatelessWidget {
  const LinegraphStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: 410,
      decoration: BoxDecoration(
          color: AppColors.statisticsBg,
          borderRadius: BorderRadius.circular(20.0)),
      child: LineChart(LineChartData(minY: 60, maxY: 70)),
    );
  }
}
