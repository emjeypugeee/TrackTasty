import 'package:fitness/theme/app_color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineGraphContainer extends StatefulWidget {
  final double goalWeight;
  final double weight;
  final String goal;
  const LineGraphContainer(
      {super.key,
      required this.goalWeight,
      required this.weight,
      required this.goal});

  @override
  State<LineGraphContainer> createState() => _LineGraphContainerState();
}

class _LineGraphContainerState extends State<LineGraphContainer> {
  String _selectedPeriod = '6 months'; // Default selection

  // Define different datasets for each time period
  // Dynamic dataset based on user's weight and goal
  Map<String, List<FlSpot>> get _chartData {
    final currentWeight = widget.weight;
    final goalWeight = widget.goalWeight;

    // Simulate progress (for demo purposes)
    return {
      '90 days': List.generate(7, (i) {
        // Simulate weight change over weeks (adjust logic as needed)
        double progress = (goalWeight - currentWeight) * (i / 6);
        return FlSpot(i.toDouble(), currentWeight + progress);
      }),
      '6 months': List.generate(6, (i) {
        // Simulate weight change over months (adjust logic as needed)
        double progress = (goalWeight - currentWeight) * (i / 5);
        return FlSpot(i.toDouble(), currentWeight + progress);
      }),
      '1 year': List.generate(12, (i) {
        // Simulate weight change over months (adjust logic as needed)
        double progress = (goalWeight - currentWeight) * (i / 11);
        return FlSpot(i.toDouble(), currentWeight + progress);
      }),
      'Overall': List.generate(5, (i) {
        // Simulate long-term progress (adjust logic as needed)
        double progress = (goalWeight - currentWeight) * (i / 4);
        return FlSpot(i.toDouble(), currentWeight + progress);
      }),
    };
  }

  // Helper method to get Y-axis range (now includes goal weight)
  double _getMinY(String period) {
    final values = _chartData[period]!.map((spot) => spot.y).toList();
    final minDataValue = values.reduce((a, b) => a < b ? a : b);
    return (minDataValue < widget.goalWeight
            ? minDataValue
            : widget.goalWeight) *
        0.95;
  }

  double _getMaxY(String period) {
    final values = _chartData[period]!.map((spot) => spot.y).toList();
    final maxDataValue = values.reduce((a, b) => a > b ? a : b);
    return (maxDataValue > widget.goalWeight
            ? maxDataValue
            : widget.goalWeight) *
        1.05;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.graphBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Center(
            child: Text(
              'Current goal: ${widget.goal}',
              style: TextStyle(color: AppColors.primaryText),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPeriodButton('90 days'),
              _buildPeriodButton('6 months'),
              _buildPeriodButton('1 year'),
              _buildPeriodButton('Overall'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: _getMinY(_selectedPeriod),
                maxY: _getMaxY(_selectedPeriod),
                minX: 0,
                maxX: _chartData[_selectedPeriod]!.last.x,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      getTitlesWidget: (value, meta) {
                        if (_selectedPeriod == '90 days') {
                          return Text(
                            'W${value.toInt() + 1}',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 12,
                            ),
                          );
                        } else if (_selectedPeriod == '6 months') {
                          const months = [
                            "Jan",
                            "Feb",
                            "Mar",
                            "Apr",
                            "May",
                            "Jun"
                          ];
                          return Text(
                            months[value.toInt()],
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 12,
                            ),
                          );
                        } else if (_selectedPeriod == '1 year') {
                          const months = [
                            "Jan",
                            "Feb",
                            "Mar",
                            "Apr",
                            "May",
                            "Jun",
                            "Jul",
                            "Aug",
                            "Sep",
                            "Oct",
                            "Nov",
                            "Dec"
                          ];
                          return Text(
                            months[value.toInt()],
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 12,
                            ),
                          );
                        } else {
                          return Text(
                            'Y${value.toInt() + 1}',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 12,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                              color: AppColors.primaryText, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey),
                    bottom: BorderSide(color: Colors.grey),
                    right: BorderSide.none,
                    top: BorderSide.none,
                  ),
                ),
                lineBarsData: [
                  // User's weight progress line (blue)
                  LineChartBarData(
                    spots: _chartData[_selectedPeriod]!,
                    isCurved: true,
                    color: Colors.blue,
                    dotData: FlDotData(show: false),
                  ),
                  // Goal weight line (dashed red)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, widget.goalWeight),
                      FlSpot(_chartData[_selectedPeriod]!.last.x,
                          widget.goalWeight),
                    ],
                    isCurved: false,
                    color: Colors.red,
                    dashArray: [5, 5],
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Text(
        period,
        style: TextStyle(
          color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
