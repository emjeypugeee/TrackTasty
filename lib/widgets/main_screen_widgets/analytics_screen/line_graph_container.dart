import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LineGraphContainer extends StatefulWidget {
  final double goalWeight;
  final String goal;
  final bool isForecasting;
  final Map<String, dynamic>? forecastData;
  final double userHeight;
  const LineGraphContainer(
      {super.key,
      required this.goalWeight,
      required this.goal,
      required this.userHeight,
      this.isForecasting = false,
      this.forecastData});

  @override
  State<LineGraphContainer> createState() => _LineGraphContainerState();
}

class _LineGraphContainerState extends State<LineGraphContainer> {
  String _selectedPeriod = '3 months';
  List<FlSpot> _weightHistory = [];
  List<DateTime> _weightDates = [];
  bool isLoading = true;
  bool isMetric = false;
  StreamSubscription? _weightHistorySubscription;
  List<FlSpot> _forecastSpots = [];
  List<DateTime> _forecastDates = [];

  @override
  void initState() {
    super.initState();
    debugPrint("📊 LineGraphContainer initialized");
    debugPrint("🎯 Goal weight: ${widget.goalWeight}, Goal: ${widget.goal}");
    debugPrint("🔮 Forecasting enabled: ${widget.isForecasting}");
    _loadData();
  }

  @override
  void dispose() {
    _weightHistorySubscription?.cancel();
    debugPrint("📊 LineGraphContainer disposed");
    super.dispose();
  }

  @override
  void didUpdateWidget(LineGraphContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("🔄 LineGraphContainer updated");
    debugPrint("   - Old forecasting: ${oldWidget.isForecasting}");
    debugPrint("   - New forecasting: ${widget.isForecasting}");
    if (widget.isForecasting != oldWidget.isForecasting ||
        widget.forecastData != oldWidget.forecastData) {
      if (widget.isForecasting) {
        debugPrint("🎯 Forecasting enabled, setting period to 6 months");
        _selectedPeriod = '6 months';
      }
      _loadWeightHistory();
      _prepareForecastData();
    }
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ No user logged in");
        return;
      }

      debugPrint("👤 Loading data for user: ${user.uid}");

      // Load current weight
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();

      if (userDoc.exists) {
        final measurementSystem = userDoc.data()?['measurementSystem'];
        setState(() {
          debugPrint("User's measurement System: $measurementSystem");
          isMetric = measurementSystem == "Metric";
        });
      }

      // Load weight history
      await _loadWeightHistory();
    } catch (e) {
      debugPrint("❌ Error loading data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWeightHistory() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    DateTime endDate = DateTime.now();
    DateTime startDate;

    if (widget.isForecasting) {
      // For forecasting, show past 2 months and next 4 months (total 6 months)
      startDate = DateTime.now().subtract(const Duration(days: 60));
      _selectedPeriod = '6 months'; // Force 6 months view
      debugPrint("📅 Forecasting mode: Loading 60 days of history + forecast");
    } else {
      switch (_selectedPeriod) {
        case '1 month':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case '3 months':
          startDate = endDate.subtract(const Duration(days: 90));
          break;
        case '6 months':
          startDate = endDate.subtract(const Duration(days: 180));
          break;
        case '1 year':
          startDate = endDate.subtract(const Duration(days: 365));
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 90));
      }
      debugPrint("📅 Normal mode: Loading $_selectedPeriod of history");
    }

    debugPrint(
        "📅 Date range: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}");

    try {
      debugPrint('🔍 Querying weight history for user: ${user.uid}');
      _weightHistorySubscription?.cancel();
      final snapshot = await FirebaseFirestore.instance
          .collection('weight_history')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date')
          .get();

      debugPrint('✅ Retrieved ${snapshot.docs.length} weight documents');

      List<FlSpot> spots = [];
      List<DateTime> dates = [];
      List<double> weights = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final weight = (data['weight'] as num).toDouble();
        final daysSinceStart = date.difference(startDate).inDays.toDouble();

        spots.add(FlSpot(daysSinceStart, weight));
        dates.add(date);
        weights.add(weight);
        debugPrint(
            '   📍 ${DateFormat('yyyy-MM-dd').format(date)}: $weight kg (day $daysSinceStart)');
      }
      debugPrint('Total spots created: ${spots.length}');
      debugPrint('First spot: ${spots.isNotEmpty ? spots.first : "N/A"}');
      debugPrint('Last spot: ${spots.isNotEmpty ? spots.last : "N/A"}');

      // Sort by date (oldest first)
      spots.sort((a, b) => a.x.compareTo(b.x));
      dates.sort((a, b) => a.compareTo(b));
      weights.sort((a, b) => a.compareTo(b));

      debugPrint('📈 Total spots created: ${spots.length}');
      if (spots.isNotEmpty) {
        debugPrint('📈 First spot: (${spots.first.x}, ${spots.first.y})');
        debugPrint('📈 Last spot: (${spots.last.x}, ${spots.last.y})');
      }

      if (mounted) {
        setState(() {
          _weightHistory = spots;
          _weightDates = dates;
          isLoading = false;
        });
        debugPrint('✅ Weight history loaded successfully');

        // Prepare forecast data if forecasting is enabled
        if (widget.isForecasting) {
          _prepareForecastData();
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading weight history: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          _weightHistory = [];
          _weightDates = [];
        });
      }
    }
  }

  void _prepareForecastData() {
    if (!widget.isForecasting || widget.forecastData == null) {
      setState(() {
        _forecastSpots = [];
        _forecastDates = [];
      });
      return;
    }

    final forecast = widget.forecastData!['projectedWeight'] as List<dynamic>;
    if (forecast.isEmpty) {
      setState(() {
        _forecastSpots = [];
        _forecastDates = [];
      });
      return;
    }

    List<FlSpot> spots = [];
    List<DateTime> dates = [];

    // Find the last actual data point to connect forecast to
    double lastX = _weightHistory.isNotEmpty ? _weightHistory.last.x : 0;
    double lastY =
        _weightHistory.isNotEmpty ? _weightHistory.last.y : widget.goalWeight;
    DateTime lastDate =
        _weightDates.isNotEmpty ? _weightDates.last : DateTime.now();

    // Start the forecast from the last historical point
    spots.add(FlSpot(lastX, lastY));
    dates.add(lastDate);

    for (var dayData in forecast) {
      final week = dayData['week'] as int;
      final projectedWeight = dayData['weight']?.toDouble() ?? lastY;

      // Calculate the x-value (days since start of history)
      final xValue = lastX + (week * 7);

      // Calculate the actual date for the forecast point
      final forecastDate = lastDate.add(Duration(days: week * 7));

      spots.add(FlSpot(xValue, projectedWeight));
    }

    setState(() {
      _forecastSpots = spots;
      _forecastDates = dates;
    });
  }

  // Calculate BMI function
  double _calculateBMI(double weight) {
    if (widget.userHeight <= 0) return 0;

    // Convert height to meters for BMI calculation
    double heightMeters = isMetric
        ? widget.userHeight / 100 // cm to meters
        : widget.userHeight * 0.0254; // inches to meters

    // Convert weight to kg if using imperial system
    double weightKg = isMetric ? weight : weight * 0.453592; // lbs to kg

    return weightKg / (heightMeters * heightMeters);
  }

  // Get BMI category
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) {
    final minX = 0.0;
    final maxX = _getMaxX();
    final adjustedX = maxX + (maxX * 0.1);

    debugPrint("📊 Building graph with:");
    debugPrint("   - Weight history points: ${_weightHistory.length}");
    debugPrint("   - Forecast spots: ${_forecastSpots.length}");
    debugPrint("   - X range: $minX to $adjustedX");
    debugPrint("   - Y range: ${_getMinY()} to ${_getMaxY()}");

    if (_weightHistory.isEmpty) {
      return Center(
        child: Text(
          'No weight history available. Start logging your weight to see progress!',
          style: TextStyle(color: AppColors.primaryText),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.graphBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Current goal: ${widget.goal}',
            style: TextStyle(color: AppColors.primaryText),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPeriodButton('1 month'),
                _buildPeriodButton('3 months'),
                _buildPeriodButton('6 months'),
                _buildPeriodButton('1 year'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                clipData: FlClipData.all(),
                minY: _getMinY(),
                maxY: _getMaxY(),
                minX: minX,
                maxX: adjustedX,
                titlesData: _buildTitlesData(maxX, minX),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey),
                    bottom: BorderSide(color: Colors.grey),
                  ),
                ),
                lineBarsData: [
                  // Actual Weight Data
                  LineChartBarData(
                    spots: _weightHistory,
                    isCurved: false,
                    color: Colors.blue,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.blue,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                  // Goal Line
                  LineChartBarData(
                    spots: [
                      FlSpot(0, widget.goalWeight),
                      FlSpot((maxX + 100), widget.goalWeight),
                    ],
                    dotData: FlDotData(
                      show: false,
                    ),
                    isCurved: false,
                    color: Colors.red,
                    dashArray: [5, 5],
                  ),

                  // Forecast data (only show when enabled)
                  if (widget.isForecasting && _forecastSpots.isNotEmpty)
                    LineChartBarData(
                      spots: _forecastSpots,
                      isCurved: true,
                      color: Colors.purple,
                      dotData: FlDotData(show: true),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isForecast = widget.isForecasting &&
                            _forecastSpots.contains(
                                spot); // Check if the point is forecasted

                        // Calculate the actual date for the data point
                        final startDate = widget.isForecasting
                            ? DateTime.now().subtract(const Duration(days: 60))
                            : DateTime.now()
                                .subtract(Duration(days: _getMaxX().toInt()));

                        final date =
                            startDate.add(Duration(days: spot.x.toInt()));
                        // Calculate BMI
                        final bmi = _calculateBMI(spot.y);
                        final bmiCategory = _getBMICategory(bmi);

                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} ${isMetric ? 'kg' : 'lbs'}\n'
                          'BMI: ${bmi.toStringAsFixed(1)} ($bmiCategory)\n'
                          '${DateFormat('MMM d, y').format(date)}'
                          '${isForecast ? ' (forecasted)' : ''}',
                          TextStyle(
                            color: isForecast
                                ? const Color.fromARGB(255, 210, 72, 235)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (spot) => Colors.blueGrey,
                  ),
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 16,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    final isDisabled = widget.isForecasting && period != '6 months';

    return TextButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
          _loadWeightHistory();
        });
      },
      child: Text(
        period,
        style: TextStyle(
          color: isDisabled
              ? AppColors.secondaryText.withValues(alpha: 0.5)
              : isSelected
                  ? AppColors.primaryText
                  : AppColors.secondaryText,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  double _getMaxX() {
    if (widget.isForecasting && _forecastSpots.isNotEmpty) {
      // For forecasting, show past 2 months + next 4 months = 6 months total
      return _forecastSpots.last.x;
    }

    if (_weightHistory.isEmpty) {
      switch (_selectedPeriod) {
        case '1 month':
          return 30;
        case '3 months':
          return 90;
        case '6 months':
          return 180;
        case '1 year':
          return 365;
        default:
          return 90;
      }
    }
    return _weightHistory.last.x;
  }

  FlTitlesData _buildTitlesData(double maxX, double minX) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: _getTitleInterval(maxX - minX),
          getTitlesWidget: (value, meta) {
            final startDate = widget.isForecasting
                ? DateTime.now().subtract(const Duration(days: 60))
                : DateTime.now().subtract(Duration(days: maxX.toInt()));

            final date = startDate.add(Duration(days: value.toInt()));

            // Use different date formats based on selected period
            String dateText;
            if (_selectedPeriod == '1 month' || _selectedPeriod == '3 months') {
              // Show full date (M/d/yy) for 1 and 3 month views
              dateText = DateFormat('M/d/yy').format(date);
            } else {
              // Show month and year for longer periods
              dateText = DateFormat('MMM y').format(date);
            }

            return Transform.rotate(
              angle: -0.4,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  dateText,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 10,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _getWeightInterval(),
          getTitlesWidget: (value, meta) {
            return Text(
              '${value.toStringAsFixed(0)} ${isMetric ? 'kg' : 'lbs'}',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 10,
              ),
            );
          },
        ),
      ),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _getWeightInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    return 20;
  }

  double _getTitleInterval(double range) {
    if (_selectedPeriod == '1 month') return 7;
    if (_selectedPeriod == '3 months') return 14;
    if (range <= 90) return 15;
    if (range <= 180) return 30;
    if (range <= 365) return 60;
    return 90;
  }

  double _getMinY() {
    if (_weightHistory.isEmpty) return widget.goalWeight * 0.9;
    final minWeight =
        _weightHistory.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    return (minWeight * 0.95)
        .clamp(widget.goalWeight * 0.8, widget.goalWeight * 1.2);
  }

  double _getMaxY() {
    if (_weightHistory.isEmpty) return widget.goalWeight * 1.1;
    final maxWeight =
        _weightHistory.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxWeight * 1.05)
        .clamp(widget.goalWeight * 0.8, widget.goalWeight * 1.2);
  }
}
