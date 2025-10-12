import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BarGraphContainer extends StatefulWidget {
  final double? calorieGoal;
  final bool isForecasting;
  final Map<String, dynamic>? forecastData;

  const BarGraphContainer({
    super.key,
    this.calorieGoal,
    this.isForecasting = false,
    this.forecastData,
  });

  @override
  State<BarGraphContainer> createState() => _BarGraphContainerState();
}

class _BarGraphContainerState extends State<BarGraphContainer> {
  DateTime _currentWeek = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<double> _calorieData = [];
  List<String> _dayLabels = [];
  bool _isLoading = true;
  double _averageCalories = 0;

  @override
  void initState() {
    super.initState();
    debugPrint("🔥 BarGraphContainer initialized");
    debugPrint("🎯 Calorie goal: ${widget.calorieGoal}");
    debugPrint("🔮 Forecasting enabled: ${widget.isForecasting}");
    _updateWeekRange();
    _loadCalorieData();
  }

  @override
  void didUpdateWidget(BarGraphContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("🔄 BarGraphContainer updated");
    debugPrint("   - Old forecasting: ${oldWidget.isForecasting}");
    debugPrint("   - New forecasting: ${widget.isForecasting}");

    if (widget.isForecasting != oldWidget.isForecasting ||
        widget.forecastData != oldWidget.forecastData) {
      _loadCalorieData();
    }
  }

  void _updateWeekRange() {
    // Get Monday of the current week (weekday 1)
    _startDate =
        _currentWeek.subtract(Duration(days: _currentWeek.weekday - 1));
    // Get Sunday of the current week
    _endDate = _startDate.add(Duration(days: 6));

    _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    _endDate =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59, 999);

    debugPrint(
        "📅 Week range: ${DateFormat('EEE yyyy-MM-dd').format(_startDate)} to ${DateFormat('EEE yyyy-MM-dd').format(_endDate)}");
  }

  void _navigateTimeRange(bool forward) {
    setState(() {
      _currentWeek = forward
          ? _currentWeek.add(Duration(days: 7))
          : _currentWeek.subtract(Duration(days: 7));

      _updateWeekRange();

      debugPrint(
          "🔄 Navigated to week: ${DateFormat('EEE yyyy-MM-dd').format(_startDate)} to ${DateFormat('EEE yyyy-MM-dd').format(_endDate)}");
      _loadCalorieData();
    });
  }

  Future<void> _loadCalorieData() async {
    if (widget.isForecasting) {
      debugPrint("🔮 Forecasting enabled, using forecast data");
      _prepareForecastData();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ No user logged in");
      return;
    }

    setState(() => _isLoading = true);

    debugPrint(
        "📥 Loading calorie data for week: ${DateFormat('EEE yyyy-MM-dd').format(_startDate)} to ${DateFormat('EEE yyyy-MM-dd').format(_endDate)}");

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('food_logs')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      debugPrint("✅ Retrieved ${snapshot.docs.length} food logs");

      // Initialize data for all 7 days of the week
      Map<DateTime, double> dailyCalories = {};
      List<DateTime> weekDays = [];

      // Create all 7 days of the week
      for (int i = 0; i < 7; i++) {
        final date = _startDate.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        weekDays.add(normalizedDate);
        dailyCalories[normalizedDate] = 0.0;
        debugPrint(
            "   📅 Initialized date: ${DateFormat('EEE yyyy-MM-dd').format(normalizedDate)}");
      }

      // Process the data from Firebase
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['date'] as Timestamp;
        final date = timestamp.toDate();
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final calories = (data['totalCalories'] as num).toDouble();

        debugPrint(
            "   🔍 Processing document for: ${DateFormat('EEE yyyy-MM-dd').format(normalizedDate)}");

        if (dailyCalories.containsKey(normalizedDate)) {
          dailyCalories[normalizedDate] = calories;
          debugPrint(
              "   ✅ SET ${DateFormat('EEE yyyy-MM-dd').format(normalizedDate)}: $calories calories");
        } else {
          debugPrint(
              "   ⚠️ Date ${DateFormat('EEE yyyy-MM-dd').format(normalizedDate)} not in current week range");
        }
      }

      // Calculate average calories
      double total = 0;
      int count = 0;
      dailyCalories.forEach((key, value) {
        total += value;
        count++;
        debugPrint("   📊 ${DateFormat('EEE').format(key)}: $value calories");
      });

      final average = count > 0 ? total / count : (widget.calorieGoal ?? 0);
      debugPrint("📊 Weekly average calories: $average");

      // Prepare data for the chart
      _calorieData = weekDays.map((date) => dailyCalories[date]!).toList();
      _dayLabels =
          weekDays.map((date) => DateFormat('E').format(date)).toList();

      setState(() {
        _averageCalories = average.toDouble();
        _isLoading = false;
      });

      debugPrint("✅ Calorie data loaded: ${_calorieData.length} days");
      debugPrint("   Days: $_dayLabels");
      debugPrint("   Data: $_calorieData");
    } catch (e) {
      debugPrint("❌ Error loading calorie data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _getMaxYValue(List<double> calorieData) {
    if (calorieData.isEmpty) {
      return widget.calorieGoal != null ? widget.calorieGoal! * 1.2 : 2000;
    }

    final maxDataValue = calorieData.reduce((a, b) => a > b ? a : b);

    if (widget.calorieGoal == null) return maxDataValue * 1.2;
    if (maxDataValue <= widget.calorieGoal! * 1.2) {
      return widget.calorieGoal! * 1.2;
    }
    return maxDataValue * 1.1;
  }

  void _prepareForecastData() {
    if (!widget.isForecasting || widget.forecastData == null) {
      debugPrint("⚠️ Forecast data not available or forecasting disabled");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint("🔮 Preparing forecast calorie data...");

    final isProvisional = widget.forecastData!['isProvisionalData'] ?? true;
    final avgCalories =
        widget.forecastData!['averageCalorieIntake']?.toDouble() ??
            widget.calorieGoal ??
            2000;

    debugPrint(
        "   - Forecast type: ${isProvisional ? 'PROVISIONAL' : 'PERSONALIZED'}");
    debugPrint("   - Average calories: $avgCalories");

    // Create forecast data for Monday to Sunday of current week
    List<double> forecastData = [];
    List<String> forecastLabels = [];

    // Get Monday to Sunday of current week
    DateTime monday =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      forecastData.add(avgCalories);
      forecastLabels.add(DateFormat('E').format(date));
      debugPrint(
          "   📅 ${DateFormat('E').format(date)}: $avgCalories calories");
    }

    setState(() {
      _calorieData = forecastData;
      _dayLabels = forecastLabels;
      _averageCalories = avgCalories;
      _isLoading = false;
    });
    debugPrint("✅ Forecast data prepared: ${_calorieData.length} days");
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
          if (!widget.isForecasting)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _navigateTimeRange(false),
                  child:
                      Text('<', style: TextStyle(color: AppColors.primaryText)),
                ),
                Text(
                  '${DateFormat('M/d/yyyy').format(_startDate)} - ${DateFormat('M/d/yyyy').format(_endDate)}',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateTimeRange(true),
                  child:
                      Text('>', style: TextStyle(color: AppColors.primaryText)),
                ),
              ],
            )
          else
            SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: _getMaxYValue(_calorieData),
                      alignment: BarChartAlignment.spaceBetween,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final isForecast = widget.isForecasting;
                            return BarTooltipItem(
                              '${rod.toY.toInt()} kcal${isForecast ? ' (forecast)' : ''}',
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(_calorieData.length, (index) {
                        final value = _calorieData[index];
                        final isForecast = widget.isForecasting;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              color: isForecast
                                  ? Colors
                                      .purple // Different color for forecast
                                  : value > 0
                                      ? Colors.yellow
                                      : Colors.grey,
                              width: 20,
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
                              if (value.toInt() >= _dayLabels.length)
                                return SizedBox();
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
                            : _getMaxYValue(_calorieData) / 4,
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
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.calorieGoal != null)
                Text('Daily Goal: ${widget.calorieGoal!.toInt()} kcal',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              Text(
                  '${widget.isForecasting ? 'Forecast' : 'Weekly Average'}: ${_averageCalories.toInt()} kcal',
                  style: TextStyle(
                      color: widget.isForecasting ? Colors.purple : Colors.blue,
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
