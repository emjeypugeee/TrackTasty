import 'package:fitness/theme/app_color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BarGraphContainer extends StatelessWidget {
  const BarGraphContainer({super.key});

  @override
  Widget build(BuildContext context) {
    double barWidth = 20;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy/MM/dd').format(now);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.graphBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () {}, child: Text('<')),
              Text(
                formattedDate,
                style: TextStyle(color: AppColors.primaryText),
              ),
              TextButton(onPressed: () {}, child: Text('>'))
            ],
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.start,
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide.none,
                    bottom: BorderSide.none,
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                          toY: 10, color: Colors.yellow, width: barWidth),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                          toY: 7, color: Colors.yellow, width: barWidth),
                    ],
                  ),
                ],

                //data
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec'
                          ];

                          return Text(
                            months[value.toInt()],
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
