import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BarGraphContainer extends StatefulWidget {
  final double? calorieGoal;
  final double? fatGoal;
  final double? carbsGoal;
  final double? proteinGoal;
  final bool isForecasting;
  final Map<String, dynamic>? forecastData;

  const BarGraphContainer({
    super.key,
    this.calorieGoal,
    this.fatGoal,
    this.carbsGoal,
    this.proteinGoal,
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
  List<double> _fatData = [];
  List<double> _carbsData = [];
  List<double> _proteinData = [];
  List<String> _dayLabels = [];
  bool _isLoading = true;
  double _averageCalories = 0;
  double _averageFat = 0;
  double _averageCarbs = 0;
  double _averageProtein = 0;
  String _selectedDataType = 'Calories';
  DateTime? _firstFoodLogDate;
  DateTime _maxFutureDate = DateTime.now().add(Duration(days: 14));

  @override
  void initState() {
    super.initState();
    debugPrint("🔥 BarGraphContainer initialized");
    debugPrint("🎯 Calorie goal: ${widget.calorieGoal}");
    debugPrint("🔮 Forecasting enabled: ${widget.isForecasting}");
    _updateWeekRange();
    _loadFirstFoodLogDate().then((_) => _loadNutritionData());
  }

  @override
  void didUpdateWidget(BarGraphContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("🔄 BarGraphContainer updated");
    debugPrint("   - Old forecasting: ${oldWidget.isForecasting}");
    debugPrint("   - New forecasting: ${widget.isForecasting}");

    if (widget.isForecasting != oldWidget.isForecasting ||
        widget.forecastData != oldWidget.forecastData) {
      _loadNutritionData();
    }
  }

  Future<void> _loadFirstFoodLogDate() async {
    if (widget.isForecasting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('food_logs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final timestamp = data['date'] as Timestamp;
        _firstFoodLogDate = timestamp.toDate();
        debugPrint(
            "📅 First food log date: ${DateFormat('yyyy-MM-dd').format(_firstFoodLogDate!)}");
      } else {
        _firstFoodLogDate = DateTime.now();
        debugPrint("📅 No food logs found, using current date as first date");
      }
    } catch (e) {
      debugPrint("❌ Error loading first food log date: $e");
      _firstFoodLogDate = DateTime.now();
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

  bool _canNavigatePast() {
    if (_firstFoodLogDate == null) return false;

    final previousWeekStart = _startDate.subtract(Duration(days: 7));
    final previousWeekEnd = _endDate.subtract(Duration(days: 7));

    // Check if the previous week's end date is after the first food log date
    return previousWeekEnd.isAfter(_firstFoodLogDate!) ||
        previousWeekEnd.isAtSameMomentAs(_firstFoodLogDate!);
  }

  bool _canNavigateFuture() {
    final nextWeekStart = _startDate.add(Duration(days: 7));
    final nextWeekEnd = _endDate.add(Duration(days: 7));

    // Check if the next week's start date is before the max future date
    return nextWeekStart.isBefore(_maxFutureDate) ||
        nextWeekStart.isAtSameMomentAs(_maxFutureDate);
  }

  void _navigateTimeRange(bool forward) {
    if (forward && !_canNavigateFuture()) {
      debugPrint("⏩ Cannot navigate to future - reached maximum future date");
      return;
    }

    if (!forward && !_canNavigatePast()) {
      debugPrint("⏪ Cannot navigate to past - reached first food log date");
      return;
    }

    setState(() {
      _currentWeek = forward
          ? _currentWeek.add(Duration(days: 7))
          : _currentWeek.subtract(Duration(days: 7));

      _updateWeekRange();

      debugPrint(
          "🔄 Navigated to week: ${DateFormat('EEE yyyy-MM-dd').format(_startDate)} to ${DateFormat('EEE yyyy-MM-dd').format(_endDate)}");
      _loadNutritionData();
    });
  }

  Future<void> _loadNutritionData() async {
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
        "📥 Loading nutrition data for week: ${DateFormat('EEE yyyy-MM-dd').format(_startDate)} to ${DateFormat('EEE yyyy-MM-dd').format(_endDate)}");

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
      Map<DateTime, double> dailyFat = {};
      Map<DateTime, double> dailyCarbs = {};
      Map<DateTime, double> dailyProtein = {};
      List<DateTime> weekDays = [];

      // Create all 7 days of the week
      for (int i = 0; i < 7; i++) {
        final date = _startDate.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        weekDays.add(normalizedDate);
        dailyCalories[normalizedDate] = 0.0;
        dailyFat[normalizedDate] = 0.0;
        dailyCarbs[normalizedDate] = 0.0;
        dailyProtein[normalizedDate] = 0.0;
        debugPrint(
            "   📅 Initialized date: ${DateFormat('EEE yyyy-MM-dd').format(normalizedDate)}");
      }

      // Process the data from Firebase
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['date'] as Timestamp;
        final date = timestamp.toDate();
        final normalizedDate = DateTime(date.year, date.month, date.day);

        final calories = (data['totalCalories'] as num?)?.toDouble() ?? 0.0;
        final fat = (data['totalFat'] as num?)?.toDouble() ?? 0.0;
        final carbs = (data['totalCarbs'] as num?)?.toDouble() ?? 0.0;
        final protein = (data['totalProtein'] as num?)?.toDouble() ?? 0.0;

        debugPrint(
            "   🔍 Processing document for: ${DateFormat('EEE yyyy-MM-dd').format(normalizedDate)}");
        debugPrint(
            "   📊 Calories: $calories, Fat: $fat, Carbs: $carbs, Protein: $protein");

        if (dailyCalories.containsKey(normalizedDate)) {
          dailyCalories[normalizedDate] = calories;
          dailyFat[normalizedDate] = fat;
          dailyCarbs[normalizedDate] = carbs;
          dailyProtein[normalizedDate] = protein;
          debugPrint(
              "   ✅ SET ${DateFormat('EEE yyyy-MM-dd').format(normalizedDate)}: $calories calories, $fat fat, $carbs carbs, $protein protein");
        } else {
          debugPrint(
              "   ⚠️ Date ${DateFormat('EEE yyyy-MM-dd').format(normalizedDate)} not in current week range");
        }
      }

      // Calculate averages
      double totalCalories = 0;
      double totalFat = 0;
      double totalCarbs = 0;
      double totalProtein = 0;
      int count = 0;

      dailyCalories.forEach((key, value) {
        totalCalories += value;
        totalFat += dailyFat[key]!;
        totalCarbs += dailyCarbs[key]!;
        totalProtein += dailyProtein[key]!;
        count++;
        debugPrint(
            "   📊 ${DateFormat('EEE').format(key)}: $value calories, ${dailyFat[key]} fat, ${dailyCarbs[key]} carbs, ${dailyProtein[key]} protein");
      });

      final avgCalories =
          count > 0 ? totalCalories / count : (widget.calorieGoal ?? 0);
      final avgFat = count > 0 ? totalFat / count : (widget.fatGoal ?? 0);
      final avgCarbs = count > 0 ? totalCarbs / count : (widget.carbsGoal ?? 0);
      final avgProtein =
          count > 0 ? totalProtein / count : (widget.proteinGoal ?? 0);

      debugPrint(
          "📊 Weekly averages - Calories: $avgCalories, Fat: $avgFat, Carbs: $avgCarbs, Protein: $avgProtein");
      debugPrint(
          "🎯 User goals - Calories: ${widget.calorieGoal}, Fat: ${widget.fatGoal}, Carbs: ${widget.carbsGoal}, Protein: ${widget.proteinGoal}");

      // Prepare data for the chart
      _calorieData = weekDays.map((date) => dailyCalories[date]!).toList();
      _fatData = weekDays.map((date) => dailyFat[date]!).toList();
      _carbsData = weekDays.map((date) => dailyCarbs[date]!).toList();
      _proteinData = weekDays.map((date) => dailyProtein[date]!).toList();
      _dayLabels =
          weekDays.map((date) => DateFormat('E').format(date)).toList();

      setState(() {
        _averageCalories = avgCalories.toDouble();
        _averageFat = avgFat.toDouble();
        _averageCarbs = avgCarbs.toDouble();
        _averageProtein = avgProtein.toDouble();
        _isLoading = false;
      });

      debugPrint("✅ Nutrition data loaded: ${_calorieData.length} days");
      debugPrint("   Days: $_dayLabels");
    } catch (e) {
      debugPrint("❌ Error loading nutrition data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<double> _getCurrentData() {
    switch (_selectedDataType) {
      case 'Fat':
        return _fatData;
      case 'Carbs':
        return _carbsData;
      case 'Protein':
        return _proteinData;
      case 'Calories':
      default:
        return _calorieData;
    }
  }

  double? _getCurrentGoal() {
    switch (_selectedDataType) {
      case 'Fat':
        return widget.fatGoal;
      case 'Carbs':
        return widget.carbsGoal;
      case 'Protein':
        return widget.proteinGoal;
      case 'Calories':
      default:
        return widget.calorieGoal;
    }
  }

  double _getCurrentAverage() {
    switch (_selectedDataType) {
      case 'Fat':
        return _averageFat;
      case 'Carbs':
        return _averageCarbs;
      case 'Protein':
        return _averageProtein;
      case 'Calories':
      default:
        return _averageCalories;
    }
  }

  String _getCurrentUnit() {
    switch (_selectedDataType) {
      case 'Fat':
      case 'Carbs':
      case 'Protein':
        return 'g';
      case 'Calories':
      default:
        return 'kcal';
    }
  }

  Color _getCurrentColor() {
    switch (_selectedDataType) {
      case 'Fat':
        return Colors.orange;
      case 'Carbs':
        return Colors.green;
      case 'Protein':
        return Colors.blue;
      case 'Calories':
      default:
        return Colors.yellow;
    }
  }

  double _getMaxYValue(List<double> data) {
    if (data.isEmpty) {
      final goal = _getCurrentGoal();
      return goal != null
          ? goal * 1.2
          : (_selectedDataType == 'Calories' ? 2000 : 100);
    }

    final maxDataValue = data.reduce((a, b) => a > b ? a : b);
    final goal = _getCurrentGoal();

    if (goal != null) {
      if (maxDataValue <= goal * 1.2) {
        return goal * 1.2;
      }
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

    debugPrint("🔮 Preparing forecast nutrition data...");

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
      _fatData = List.filled(7, 0.0);
      _carbsData = List.filled(7, 0.0);
      _proteinData = List.filled(7, 0.0);
      _dayLabels = forecastLabels;
      _averageCalories = avgCalories;
      _averageFat = 0;
      _averageCarbs = 0;
      _averageProtein = 0;
      _isLoading = false;
    });
    debugPrint("✅ Forecast data prepared: ${_calorieData.length} days");
  }

  Widget _buildDataTypeButton(String dataType) {
    final isSelected = _selectedDataType == dataType;
    final isDisabled = widget.isForecasting && dataType != 'Calories';

    return TextButton(
      onPressed: isDisabled
          ? null
          : () {
              setState(() {
                _selectedDataType = dataType;
              });
            },
      child: Text(
        dataType,
        style: TextStyle(
          color: isDisabled
              ? AppColors.secondaryText.withOpacity(0.5)
              : isSelected
                  ? AppColors.primaryText
                  : AppColors.secondaryText,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _getCurrentData();
    final currentAverage = _getCurrentAverage();
    final currentUnit = _getCurrentUnit();
    final currentColor = _getCurrentColor();
    final currentGoal = _getCurrentGoal();

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
                  onPressed: _canNavigatePast()
                      ? () => _navigateTimeRange(false)
                      : null,
                  child: Text('<',
                      style: TextStyle(
                          color: _canNavigatePast()
                              ? AppColors.primaryText
                              : AppColors.primaryText.withOpacity(0.3))),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${DateFormat('M/d/yyyy').format(_startDate)} - ${DateFormat('M/d/yyyy').format(_endDate)}',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _canNavigateFuture()
                      ? () => _navigateTimeRange(true)
                      : null,
                  child: Text('>',
                      style: TextStyle(
                          color: _canNavigateFuture()
                              ? AppColors.primaryText
                              : AppColors.primaryText.withOpacity(0.3))),
                ),
              ],
            )
          else
            SizedBox(height: 10),

          // Data type selector buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDataTypeButton('Calories'),
                _buildDataTypeButton('Fat'),
                _buildDataTypeButton('Carbs'),
                _buildDataTypeButton('Protein'),
              ],
            ),
          ),
          SizedBox(height: 10),

          SizedBox(
            height: 200,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: _getMaxYValue(currentData),
                      alignment: BarChartAlignment.spaceBetween,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final isForecast = widget.isForecasting;
                            return BarTooltipItem(
                              '${rod.toY.toInt()} $currentUnit${isForecast ? ' (forecast)' : ''}',
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(currentData.length, (index) {
                        final value = currentData[index];
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
                                      ? currentColor
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
                        horizontalInterval: currentGoal != null
                            ? currentGoal! / 4
                            : _getMaxYValue(currentData) / 4,
                        getDrawingHorizontalLine: (value) {
                          if (currentGoal != null &&
                              (value - currentGoal!).abs() < 0.1) {
                            return FlLine(
                              color: Colors.red,
                              strokeWidth: 2,
                              dashArray: [5, 5],
                            );
                          }
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
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
              if (currentGoal != null)
                Text('Daily Goal: ${currentGoal!.toInt()} $currentUnit',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              Text(
                  '${widget.isForecasting ? 'Forecast' : 'Weekly Average'}: ${currentAverage.toInt()} $currentUnit',
                  style: TextStyle(
                      color:
                          widget.isForecasting ? Colors.purple : currentColor,
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
