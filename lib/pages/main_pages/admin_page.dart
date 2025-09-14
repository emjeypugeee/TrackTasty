import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/services/fat_secret_api_service.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _adminSections[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
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

  static Future<Map<String, dynamic>> getDeepSeekStatus() async {
    try {
      final startTime = DateTime.now();

      // Test DeepSeek API with a simpler, more reliable endpoint
      final response = await http.get(
        Uri.parse('https://api.deepseek.com/v1/models'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['DEEPSEEK_API_KEY']}',
        },
      );

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      // DeepSeek returns 200 even for unauthorized, so check for valid response
      final isAvailable =
          response.statusCode == 200 && response.body.contains('deepseek');

      return {
        'status': isAvailable ? 'Connected' : 'Unavailable',
        'response_time_ms': responseTime,
        'last_checked': DateTime.now(),
        'error': !isAvailable ? 'API not responding properly' : null,
      };
    } catch (e) {
      return {
        'status': 'Unavailable',
        'response_time_ms': null,
        'last_checked': DateTime.now(),
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getFatSecretStatus() async {
    try {
      final startTime = DateTime.now();

      // Test FatSecret API with a more robust check
      final service = FatSecretApiService();
      final result = await service.searchFood('apple').timeout(
            const Duration(seconds: 10),
            onTimeout: () => [],
          );

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      // FatSecret returns empty array when rate limited but still connected
      final isConnected = result != null;
      final status = isConnected ? 'Connected' : 'Limited';

      return {
        'status': status,
        'response_time_ms': responseTime,
        'last_checked': DateTime.now(),
        'error': !isConnected ? 'No response from API' : null,
      };
    } on TimeoutException {
      return {
        'status': 'Timeout',
        'response_time_ms': null,
        'last_checked': DateTime.now(),
        'error': 'Request timed out',
      };
    } catch (e) {
      return {
        'status': 'Unavailable',
        'response_time_ms': null,
        'last_checked': DateTime.now(),
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getSystemMetrics() async {
    final firebaseHealth = await getFirebaseHealthStatus();
    final deepSeekStatus = await getDeepSeekStatus();
    final fatSecretStatus = await getFatSecretStatus();

    return {
      'firebase': firebaseHealth,
      'deepseek': deepSeekStatus,
      'fatsecret': fatSecretStatus,
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

//
// DASHBOARD SECTION
//
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isLoading ? null : _loadMetrics,
              ),
            ],
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
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> metrics) {
    final firebaseMetrics = metrics['firebase'] as Map<String, dynamic>;
    final deepSeekMetrics = metrics['deepseek'] as Map<String, dynamic>;
    final fatSecretMetrics = metrics['fatsecret'] as Map<String, dynamic>;

    return GridView.count(
      shrinkWrap: true,
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
          'Users',
          '${firebaseMetrics['users_count']}',
          Icons.people,
          Colors.blue,
        ),
        _buildMetricCard(
          'Food Logs',
          '${firebaseMetrics['food_logs_count']}',
          Icons.restaurant,
          Colors.purple,
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
                fontSize: 16,
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

// Account Management Section with functionality
class AccountManagementSection extends StatefulWidget {
  const AccountManagementSection({super.key});

  @override
  State<AccountManagementSection> createState() =>
      _AccountManagementSectionState();
}

class _AccountManagementSectionState extends State<AccountManagementSection> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _createAdminAccount() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(_emailController.text)
          .set({
        'isAdmin': true,
        'email': _emailController.text,
        'adminGrantedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Admin privileges granted to ${_emailController.text}')),
      );
      _emailController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _viewAllUsers() async {
    // Navigate user list (NO FUNCTIONS YET)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening user list...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Create Admin Account
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'User Email',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _createAdminAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Grant Admin Privileges',
                style: TextStyle(color: AppColors.primaryText)),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _viewAllUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('View All Users',
                style: TextStyle(color: AppColors.primaryText)),
          ),
        ],
      ),
    );
  }
}

//
// Chatbot Management Section
//
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
          Center(
            child: Text("Work in Progress",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          // NO FUNCTIONS YET
        ],
      ),
    );
  }
}

//
// Feedback Management Section
//
class FeedbackManagementSection extends StatefulWidget {
  const FeedbackManagementSection({super.key});

  @override
  State<FeedbackManagementSection> createState() =>
      _FeedbackManagementSectionState();
}

class _FeedbackManagementSectionState extends State<FeedbackManagementSection> {
  String? _selectedCategory;
  String? _selectedStatus;
  final List<String> _categories = [
    'Bug',
    'Suggestion',
    'Inquiry',
    'Feature Request',
    'Complaint',
    'Other'
  ];
  final List<String> _statuses = ['new', 'in-progress', 'resolved', 'ignore'];

  void _showFeedbackDetails(Map<String, dynamic> feedback) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Category', feedback['category'] ?? 'Unknown'),
            _buildDetailRow('User', feedback['userEmail'] ?? 'Unknown'),
            _buildDetailRow('Status', feedback['status'] ?? 'new'),
            _buildDetailRow('Date', _formatTimestamp(feedback['timestamp'])),
            const SizedBox(height: 16),
            Text(
              'Message:',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              feedback['message'] ?? 'No message',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _respondToFeedback(feedback),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Respond via Email'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().split('.').first;
    }
    return 'Unknown';
  }

  Future<void> _respondToFeedback(Map<String, dynamic> feedback) async {
    final email = feedback['userEmail']?.toString();
    if (email == null || email.isEmpty) {
      print('No email provided');
      return;
    }

    try {
      // Create a safe email URI
      final subject = Uri.encodeComponent('Re: Your Feedback - TrackTasty');
      final body = Uri.encodeComponent(
        'Hello,\n\nThank you for your feedback regarding "${feedback['category']}".\n\n',
      );

      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=$subject&body=$body',
      );

      debugPrint('Attempting to launch: $emailLaunchUri');

      // Use a timeout to prevent hanging
      final launchFuture = launchUrl(emailLaunchUri);
      final success = await launchFuture.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Email launch timed out');
          return false;
        },
      );

      if (!success) {
        _showEmailError(context);
      }
    } on FormatException catch (e) {
      debugPrint('Invalid email format: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email address')),
      );
    } catch (e) {
      debugPrint('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening email client')),
      );
    }
  }

  void _showEmailError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No email app found')),
    );
  }

  Future<void> _updateFeedbackStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(docId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feedback Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Filter buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Category filter
              DropdownButton<String>(
                value: _selectedCategory,
                hint: Text('Filter by Category',
                    style: TextStyle(color: Colors.white)),
                dropdownColor: Colors.grey[900],
                style: TextStyle(color: Colors.white),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedCategory = newValue);
                },
              ),

              // Status filter
              DropdownButton<String>(
                value: _selectedStatus,
                hint: Text('Filter by Status',
                    style: TextStyle(color: Colors.white)),
                dropdownColor: Colors.grey[900],
                style: TextStyle(color: Colors.white),
                items: _statuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedStatus = newValue);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
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

                var filteredDocs = snapshot.data!.docs;
                if (_selectedCategory != null) {
                  filteredDocs = filteredDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['category'] == _selectedCategory;
                  }).toList();
                }
                if (_selectedStatus != null) {
                  filteredDocs = filteredDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == _selectedStatus;
                  }).toList();
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final feedback = filteredDocs[index];
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
                              style: TextStyle(
                                color: _getStatusColor(data['status'] ?? 'new'),
                              ),
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
                              value: 'change_status',
                              child: Text('Change Status'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'view') {
                              debugPrint("Showing Feedback Details");
                              _showFeedbackDetails(data);
                            } else if (value == 'respond') {
                              debugPrint("Showing Feedback Response");
                              _respondToFeedback(data);
                            } else if (value == 'change_status') {
                              debugPrint("Showing Change Status");
                              _showStatusChangeDialog(
                                  feedback.id, data['status'] ?? 'new');
                            }
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

  void _showStatusChangeDialog(String docId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Change Status', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses.map((status) {
            return ListTile(
              title: Text(status, style: TextStyle(color: Colors.white)),
              trailing: currentStatus == status
                  ? Icon(Icons.check, color: AppColors.primaryColor)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateFeedbackStatus(docId, status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.orange;
      case 'in-progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'ignore':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }
}
