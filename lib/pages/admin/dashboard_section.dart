//
// Dashboard Section
//
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness/pages/admin/system_metrics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardSection extends StatefulWidget {
  const DashboardSection({super.key});

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;
  Timer? _refreshTimer;
  Map<String, dynamic> _userStats = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _loadUserStats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadMetrics();
      _loadUserStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    final metrics = await SystemMetricsService.getSystemMetrics();
    if (mounted) {
      setState(() {
        _metrics = metrics;
      });
    }
  }

  Future<void> _loadUserStats() async {
    try {
      // Get total users count
      final usersCount =
          await FirebaseFirestore.instance.collection('Users').count().get();

      // Get users created in the last 7 days
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final newUsersCount = await FirebaseFirestore.instance
          .collection('Users')
          .where('dateAccountCreated', isGreaterThanOrEqualTo: weekAgo)
          .count()
          .get();

      // Get users with activity in the last 24 hours
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final activeUsersCount = await FirebaseFirestore.instance
          .collection('user_achievements')
          .where('last_logged_date', isGreaterThanOrEqualTo: yesterday)
          .count()
          .get();

      // Get food logs count
      final foodLogsCount = await FirebaseFirestore.instance
          .collection('food_logs')
          .count()
          .get();

      if (mounted) {
        setState(() {
          _userStats = {
            'totalUsers': usersCount.count,
            'newUsersThisWeek': newUsersCount.count,
            'activeUsersToday': activeUsersCount.count,
            'totalFoodLogs': foodLogsCount.count,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'connected':
      case 'available':
      case 'online':
        return '✅';
      case 'unhealthy':
      case 'error':
      case 'unavailable':
      case 'offline':
        return '❌';
      case 'limited':
      case 'timeout':
        return '⚠️';
      default:
        return '⚠️';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'connected':
      case 'available':
      case 'online':
        return Colors.green;
      case 'unhealthy':
      case 'error':
      case 'unavailable':
      case 'offline':
        return Colors.red;
      case 'limited':
      case 'timeout':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  Widget _buildUserStats() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Statistics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Users',
                  _userStats['totalUsers']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  'New This Week',
                  _userStats['newUsersThisWeek']?.toString() ?? '0',
                  Icons.new_releases,
                  Colors.green,
                ),
                _buildStatItem(
                  'Active Today',
                  _userStats['activeUsersToday']?.toString() ?? '0',
                  Icons.online_prediction,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Food Logs',
                  _userStats['totalFoodLogs']?.toString() ?? '0',
                  Icons.restaurant,
                  Colors.purple,
                ),
                _buildStatItem(
                  'Avg Logs/User',
                  _userStats['totalUsers'] != null &&
                          _userStats['totalUsers']! > 0
                      ? (_userStats['totalFoodLogs']! /
                              _userStats['totalUsers']!)
                          .toStringAsFixed(1)
                      : '0',
                  Icons.analytics,
                  Colors.teal,
                ),
                _buildStatItem(
                  'Activity Rate',
                  _userStats['totalUsers'] != null &&
                          _userStats['totalUsers']! > 0
                      ? '${((_userStats['activeUsersToday']! / _userStats['totalUsers']!) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  Icons.trending_up,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'System Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() => _isLoading = true);
                          _loadMetrics();
                          _loadUserStats();
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // User Statistics
            _buildUserStats(),
            const SizedBox(height: 20),

            const Text(
              'System Metrics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_metrics == null)
              const Center(
                child: Text(
                  'Failed to load metrics',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              _buildMetricsGrid(_metrics!),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> metrics) {
    final firebaseMetrics = metrics['firebase'] as Map<String, dynamic>;
    final deepSeekMetrics = metrics['deepseek'] as Map<String, dynamic>;
    final fatSecretMetrics = metrics['fatsecret'] as Map<String, dynamic>;
    final geminiMetrics = metrics['gemini'] as Map<String, dynamic>;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Server Status',
          '${_getStatusIcon(firebaseMetrics['status'])} ${firebaseMetrics['status']}',
          Icons.cloud,
          _getStatusColor(firebaseMetrics['status']),
        ),
        _buildMetricCard(
          'Database',
          '${_getStatusIcon(firebaseMetrics['firestore_status'])} ${firebaseMetrics['firestore_status']}',
          Icons.storage,
          _getStatusColor(firebaseMetrics['firestore_status']),
        ),
        _buildMetricCard(
          'DeepSeek API',
          '${_getStatusIcon(deepSeekMetrics['status'])} ${deepSeekMetrics['status']}',
          Icons.smart_toy,
          _getStatusColor(deepSeekMetrics['status']),
        ),
        _buildMetricCard(
          'FatSecret API',
          '${_getStatusIcon(fatSecretMetrics['status'])} ${fatSecretMetrics['status']}',
          Icons.fastfood,
          _getStatusColor(fatSecretMetrics['status']),
        ),
        _buildMetricCard(
          'Gemini API',
          '${_getStatusIcon(geminiMetrics['status'])} ${geminiMetrics['status']}',
          Icons.camera,
          _getStatusColor(geminiMetrics['status']),
        ),
        _buildMetricCard(
          'Response Time',
          '${firebaseMetrics['response_time_ms']}ms',
          Icons.speed,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
