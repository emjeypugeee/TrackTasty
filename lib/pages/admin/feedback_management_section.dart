//
// Feedback Management Section
//
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    'All Categories',
    'Bug',
    'Suggestion',
    'Complaint',
    'Other'
  ];
  final List<String> _statuses = [
    'All Statuses',
    'new',
    'in-progress',
    'resolved',
    'ignore'
  ];

  void _showFeedbackDetails(Map<String, dynamic> feedback) {
    final hasChatHistory =
        feedback['history'] != null && (feedback['history'] as List).isNotEmpty;

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
            if (feedback['type'] != null)
              _buildDetailRow('Type', feedback['type'] ?? ''),
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

            // Appears only if history exists, Show Chat Conversation
            if (hasChatHistory) ...[
              ElevatedButton(
                onPressed: () => _showChatHistory(feedback),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('View Chat History'),
              ),
              const SizedBox(height: 10),
            ],

            /*ElevatedButton(
              onPressed: () => _respondToFeedback(feedback),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Respond via Email'),
            ),*/
          ],
        ),
      ),
    );
  }

  // Display Chat History through Dialog
  void _showChatHistory(Map<String, dynamic> feedback) {
    final history = feedback['history'] as List<dynamic>?;
    if (history == null || history.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 500,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chat History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Chat History Content
              Expanded(
                child: Container(
                  color: Colors.grey[850],
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final message = history[index] as Map<String, dynamic>;
                      final role = message['role']?.toString() ?? 'unknown';
                      final content = message['content']?.toString() ?? '';

                      return _buildChatMessage(role, content, index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessage(String role, String content, int index) {
    final isUser = role == 'user';
    final messageNumber = index + 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.blue[800]?.withOpacity(0.3)
            : Colors.green[800]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUser ? Colors.blue[400]! : Colors.green[400]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#$messageNumber ',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isUser ? 'User' : 'Assistant',
                style: TextStyle(
                  color: isUser ? Colors.blue[200] : Colors.green[200],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: Colors.white),
          ),
        ],
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
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[300]),
            ),
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
      debugPrint('No email provided');
      return;
    }

    try {
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
    return SingleChildScrollView(
      child: Padding(
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
                      value: category == 'All Categories' ? null : category,
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
                      value: status == 'All Statuses' ? null : status,
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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
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
                      final hasChatHistory = data['history'] != null &&
                          (data['history'] as List).isNotEmpty;

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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Status: ${data['status'] ?? 'new'} - ${timestamp.toString().split(' ')[0]}',
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            data['status'] ?? 'new'),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (hasChatHistory) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[800],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Chatbot Report',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Text(
                                  'View Details',
                                  style:
                                      TextStyle(color: AppColors.primaryText),
                                ),
                              ),
                              /*const PopupMenuItem(
                                value: 'respond',
                                child: Text('Respond', style: TextStyle(color: AppColors.primaryText),),
                              ),*/
                              const PopupMenuItem(
                                value: 'change_status',
                                child: Text(
                                  'Change Status',
                                  style:
                                      TextStyle(color: AppColors.primaryText),
                                ),
                              ),
                            ],
                            color: AppColors.containerBg,
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
          children: _statuses
              .where((status) => status != 'All Statuses')
              .map((status) {
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
