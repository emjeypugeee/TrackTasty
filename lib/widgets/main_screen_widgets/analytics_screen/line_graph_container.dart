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
  const LineGraphContainer(
      {super.key, required this.goalWeight, required this.goal});

  @override
  State<LineGraphContainer> createState() => _LineGraphContainerState();
}

class _LineGraphContainerState extends State<LineGraphContainer> {
  String _selectedPeriod = '3 months';
  List<FlSpot> _weightHistory = [];
  bool isLoading = true;
  bool isMetric = false;
  StreamSubscription? _weightHistorySubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _weightHistorySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
      debugPrint("Error loading data: $e");
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

    try {
      debugPrint('Querying weight history for user: ${user.uid}');
      _weightHistorySubscription?.cancel();
      final snapshot = await FirebaseFirestore.instance
          .collection('weight_history')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date')
          .get();

      debugPrint('Retrieved ${snapshot.docs.length} documents');

      List<FlSpot> spots = [];
      List<DateTime> dates = [];
      List<double> weights = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        debugPrint('Date: $date');
        final weight = (data['weight'] as num).toDouble();
        debugPrint('Weight: $weight (type: ${data['weight'].runtimeType})');

        // Calculate days since start
        final daysSinceStart = date.difference(startDate).inDays.toDouble();
        debugPrint('Days since start: $daysSinceStart');
        spots.add(FlSpot(daysSinceStart, weight));
        dates.add(date);
        weights.add(weight);
        debugPrint('Added spot: (${daysSinceStart}, $weight)\n');
      }
      debugPrint('Total spots created: ${spots.length}');
      debugPrint('First spot: ${spots.isNotEmpty ? spots.first : "N/A"}');
      debugPrint('Last spot: ${spots.isNotEmpty ? spots.last : "N/A"}');

      // Sort by date (oldest first)
      spots.sort((a, b) => a.x.compareTo(b.x));
      dates.sort((a, b) => a.compareTo(b));
      weights.sort((a, b) => a.compareTo(b));
      if (mounted) {
        setState(() {
          _weightHistory = spots;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading weight history: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          _weightHistory = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final minX = 0.0;
    final maxX = _getMaxX();
    final adjustedX = maxX + (maxX * 0.1);

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
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = DateFormat('MMM d, y').format(
                          DateTime.now().subtract(Duration(
                            days: (maxX - spot.x).toInt(),
                          )),
                        );
                        return LineTooltipItem(
                          isMetric
                              ? '${spot.y.toStringAsFixed(1)} kg\n$date'
                              : '${spot.y.toStringAsFixed(1)} lbs\n$date',
                          const TextStyle(color: Colors.white),
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
          color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  double _getMaxX() {
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
            final date = DateTime.now().subtract(Duration(
              days: (maxX - value).toInt(),
            ));
            return Transform.rotate(
              angle: -0.4,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('MMM y').format(date),
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
    if (range <= 30) return 7;
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
