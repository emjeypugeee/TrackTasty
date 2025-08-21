import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BarGraphContainer extends StatefulWidget {
  final double? calorieGoal;

  const BarGraphContainer({
    super.key,
    this.calorieGoal,
  });

  @override
  State<BarGraphContainer> createState() => _BarGraphContainerState();
}

class _BarGraphContainerState extends State<BarGraphContainer> {
  DateTime _startDate =
      DateTime.now().subtract(Duration(days: 6)); // Default 7 days
  DateTime _endDate = DateTime.now();
  int _daysToShow = 7; // Default days to show
  List<double> _calorieData = [];
  List<String> _dayLabels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalorieData();
  }

  Future<void> _loadCalorieData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('food_logs')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      // Initialize data lists
      Map<DateTime, double> dailyCalories = {};
      for (int i = 0; i <= _endDate.difference(_startDate).inDays; i++) {
        final date = _startDate.add(Duration(days: i));
        dailyCalories[DateTime(date.year, date.month, date.day)] = 0;
      }

      // Process the data
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final keyDate = DateTime(date.year, date.month, date.day);
        if (dailyCalories.containsKey(keyDate)) {
          dailyCalories[keyDate] = (data['totalCalories'] as num).toDouble();
        }
      }

      // Prepare data for the chart
      final sortedDates = dailyCalories.keys.toList()
        ..sort((a, b) => a.compareTo(b));

      setState(() {
        _calorieData = sortedDates.map((date) => dailyCalories[date]!).toList();
        _dayLabels = sortedDates.map((date) {
          if (_daysToShow <= 14) {
            return DateFormat('E').format(date); // Short day name for 1-2 weeks
          } else if (_daysToShow <= 30) {
            return DateFormat('MMM d')
                .format(date); // Month and day for 3-4 weeks
          } else {
            return DateFormat('MM/dd')
                .format(date); // Numeric format for longer periods
          }
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading calorie data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeTimeRange(int days) {
    setState(() {
      _daysToShow = days;
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days - 1));
      _loadCalorieData();
    });
  }

  void _navigateTimeRange(bool forward) {
    final duration = Duration(days: _daysToShow);
    setState(() {
      if (forward) {
        _startDate = _startDate.add(duration);
        _endDate = _endDate.add(duration);
      } else {
        _startDate = _startDate.subtract(duration);
        _endDate = _endDate.subtract(duration);
      }
      _loadCalorieData();
    });
  }

  double _getMaxYValue() {
    if (_calorieData.isEmpty) {
      return widget.calorieGoal != null ? widget.calorieGoal! * 1.2 : 2000;
    }

    final maxDataValue = _calorieData.reduce((a, b) => a > b ? a : b);

    if (widget.calorieGoal == null) return maxDataValue * 1.2;
    if (maxDataValue <= widget.calorieGoal! * 1.2) {
      return widget.calorieGoal! * 1.2;
    }
    return maxDataValue * 1.1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.graphBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _navigateTimeRange(false),
                child:
                    Text('<', style: TextStyle(color: AppColors.primaryText)),
              ),
              DropdownButton<int>(
                value: _daysToShow,
                dropdownColor: AppColors.graphBg,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryText),
                style: TextStyle(color: AppColors.primaryText),
                items: [7, 14, 30, 60, 90].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      value == 7
                          ? '1 Week'
                          : value == 14
                              ? '2 Weeks'
                              : value == 30
                                  ? '1 Month'
                                  : value == 60
                                      ? '2 Months'
                                      : '3 Months',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  );
                }).toList(),
                onChanged: (value) => _changeTimeRange(value!),
              ),
              TextButton(
                onPressed: () => _navigateTimeRange(true),
                child:
                    Text('>', style: TextStyle(color: AppColors.primaryText)),
              ),
            ],
          ),
          SizedBox(
            height: 200,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: _getMaxYValue(),
                      alignment: BarChartAlignment.spaceBetween,
                      groupsSpace: _daysToShow > 14 ? 8 : 12,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()} kcal', // Add "kcal" here
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(_calorieData.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: _calorieData[index],
                              color: _calorieData[index] > 0
                                  ? Colors.yellow
                                  : Colors.grey,
                              width: _daysToShow > 14 ? 5 : 20,
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                  color: AppColors.primaryText, fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final interval = (_daysToShow > 14)
                                  ? (_daysToShow > 30 ? 7 : 3)
                                  : 1;
                              if (value.toInt() % interval != 0) {
                                return SizedBox.shrink();
                              }
                              return Transform.rotate(
                                angle: -0.4,
                                child: Text(
                                  _dayLabels[value.toInt()],
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(color: Colors.grey),
                          bottom: BorderSide(color: Colors.grey),
                          top: BorderSide.none,
                          right: BorderSide(color: Colors.grey),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: widget.calorieGoal != null
                            ? widget.calorieGoal! / 4
                            : _getMaxYValue() / 4,
                        getDrawingHorizontalLine: (value) {
                          if (widget.calorieGoal != null &&
                              (value - widget.calorieGoal!).abs() < 0.1) {
                            return FlLine(
                              color: Colors.red,
                              strokeWidth: 2,
                              dashArray: [5, 5],
                            );
                          }
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
          ),
          if (widget.calorieGoal != null) ...[
            SizedBox(height: 10),
            Text('Daily Goal: ${widget.calorieGoal!.toInt()} kcal',
                style: TextStyle(color: Colors.red, fontSize: 12))
          ],
        ],
      ),
    );
  }
}
