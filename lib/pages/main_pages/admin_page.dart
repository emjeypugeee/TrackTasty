import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final List<Widget> _adminSections = [
    const DashboardSection(),
    const AccountManagementSection(),
    const ChatbotManagementSection(),
    const FeedbackManagementSection(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.selected,
            backgroundColor: Colors.grey[900],
            selectedLabelTextStyle: const TextStyle(color: Colors.white),
            unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard, color: Colors.grey),
                selectedIcon: Icon(Icons.dashboard, color: Colors.white),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people, color: Colors.grey),
                selectedIcon: Icon(Icons.people, color: Colors.white),
                label: Text('Accounts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat, color: Colors.grey),
                selectedIcon: Icon(Icons.chat, color: Colors.white),
                label: Text('Chatbot'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.feedback, color: Colors.grey),
                selectedIcon: Icon(Icons.feedback, color: Colors.white),
                label: Text('Feedback'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),

          // Main Content
          Expanded(
            child: _adminSections[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// System Metrics Service
class SystemMetricsService {
  static Future<Map<String, dynamic>> getFirebaseHealthStatus() async {
    try {
      final startTime = DateTime.now();

      // Test Auth
      final auth = FirebaseAuth.instance;
      final authUser = auth.currentUser;
      final authStatus = authUser != null ? 'Connected' : 'No active user';

      // Test Firestore
      final firestore = FirebaseFirestore.instance;
      final testTime = DateTime.now();
      await firestore.collection('health_check').doc('test').set({
        'timestamp': testTime,
      });
      await firestore.collection('health_check').doc('test').delete();

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      // Get Firestore stats
      final usersCount = await _getCollectionCount('Users');
      final foodLogsCount = await _getCollectionCount('food_logs');

      return {
        'status': 'Healthy',
        'response_time_ms': responseTime,
        'auth_status': authStatus,
        'firestore_status': 'Connected',
        'users_count': usersCount,
        'food_logs_count': foodLogsCount,
        'last_checked': DateTime.now(),
        'error': null,
      };
    } catch (e) {
      return {
        'status': 'Unhealthy',
        'response_time_ms': null,
        'auth_status': 'Error',
        'firestore_status': 'Error',
        'users_count': 0,
        'food_logs_count': 0,
        'last_checked': DateTime.now(),
        'error': e.toString(),
      };
    }
  }

  static Future<int?> _getCollectionCount(String collectionName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .count()
          .get();
      return snapshot.count;
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getSystemMetrics() async {
    final firebaseHealth = await getFirebaseHealthStatus();

    return {
      'firebase': firebaseHealth,
      'app_version': '1.0.0',
      'timestamp': DateTime.now(),
      'device_platform': 'Flutter',
      'connection_type': await _getConnectionType(),
    };
  }

  static Future<String> _getConnectionType() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      return response.statusCode == 200 ? 'Online' : 'Offline';
    } catch (e) {
      return 'Offline';
    }
  }
}

// Dashboard Section with real metrics
class DashboardSection extends StatefulWidget {
  const DashboardSection({super.key});

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    // Refresh metrics every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadMetrics();
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
        _isLoading = false;
      });
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'connected':
      case 'online':
        return '✅';
      case 'unhealthy':
      case 'error':
      case 'offline':
        return '❌';
      default:
        return '⚠️';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'connected':
      case 'online':
        return Colors.green;
      case 'unhealthy':
      case 'error':
      case 'offline':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isLoading ? null : _loadMetrics,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> metrics) {
    final firebaseMetrics = metrics['firebase'] as Map<String, dynamic>;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Server Status',
          '${_getStatusIcon(firebaseMetrics['status'])} ${firebaseMetrics['status']}',
          Icons.cloud,
          _getStatusColor(firebaseMetrics['status']),
          subtitle:
              'Last checked: ${_formatDateTime(firebaseMetrics['last_checked'])}',
        ),
        _buildMetricCard(
          'Database Health',
          '${_getStatusIcon(firebaseMetrics['firestore_status'])} ${firebaseMetrics['firestore_status']}',
          Icons.storage,
          _getStatusColor(firebaseMetrics['firestore_status']),
          subtitle: 'Response: ${firebaseMetrics['response_time_ms']}ms',
        ),
        _buildMetricCard(
          'Authentication',
          '${_getStatusIcon(firebaseMetrics['auth_status'])} ${firebaseMetrics['auth_status']}',
          Icons.security,
          _getStatusColor(firebaseMetrics['auth_status']),
        ),
        _buildMetricCard(
          'Registered Users',
          '${firebaseMetrics['users_count']}',
          Icons.people,
          Colors.blue,
          subtitle: 'Active accounts',
        ),
        _buildMetricCard(
          'Food Logs',
          '${firebaseMetrics['food_logs_count']}',
          Icons.restaurant,
          Colors.purple,
          subtitle: 'Total entries',
        ),
        _buildMetricCard(
          'Connection',
          '${_getStatusIcon(metrics['connection_type'])} ${metrics['connection_type']}',
          Icons.wifi,
          _getStatusColor(metrics['connection_type']),
          subtitle: 'Network status',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String subtitle = '',
  }) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime is DateTime) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (dateTime is String) {
      return dateTime;
    }
    return 'N/A';
  }
}

// The rest of your classes (AccountManagementSection, ChatbotManagementSection,
// FeedbackManagementSection) remain unchanged from your original code...
// Account Management Section
class AccountManagementSection extends StatelessWidget {
  const AccountManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text('Create Admin Account'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('View All Users'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final user = snapshot.data!.docs[index];
                    final data = user.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                        data['username'] ?? 'No username',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        data['email'] ?? 'No email',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Chatbot Management Section
class ChatbotManagementSection extends StatelessWidget {
  const ChatbotManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chatbot Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Response Boundaries',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Max Response Length',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    initialValue: '500',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Sensitivity Level',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    initialValue: 'Medium',
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Conversations',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 10),
                // Would typically show conversation logs here
                Text(
                  'Conversation monitoring feature would be implemented here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Feedback Management Section
class FeedbackManagementSection extends StatelessWidget {
  const FeedbackManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feedback Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text('Filter by Category'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Export Feedback'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feedback')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No feedback yet'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final feedback = snapshot.data!.docs[index];
                    final data = feedback.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          '${data['category']} - ${data['userEmail'] ?? 'Unknown'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['message'] ?? 'No message',
                              style: const TextStyle(color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Status: ${data['status'] ?? 'new'} - ${timestamp.toString().split(' ')[0]}',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                            const PopupMenuItem(
                              value: 'respond',
                              child: Text('Respond'),
                            ),
                            const PopupMenuItem(
                              value: 'resolve',
                              child: Text('Mark as Resolved'),
                            ),
                          ],
                          onSelected: (value) {
                            // Handle feedback actions
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
