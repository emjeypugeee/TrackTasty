//
// Chatbot Management Section
//
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:fitness/services/deepseek_api_service.dart';
import 'package:intl/intl.dart';

class ChatbotManagementSection extends StatefulWidget {
  const ChatbotManagementSection({super.key});

  @override
  State<ChatbotManagementSection> createState() =>
      _ChatbotManagementSectionState();
}

class _ChatbotManagementSectionState extends State<ChatbotManagementSection> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentVersion = '';
  Map<String, dynamic>? _currentMonthUsage;
  Map<String, dynamic>? _totalUsage;
  List<Map<String, dynamic>> _monthlyHistory = [];
  bool _isLoadingUsage = true;

  @override
  void initState() {
    super.initState();
    _loadSystemPrompt();
    _loadUsageData();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemPrompt() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chatbot_config')
          .doc('system_prompt')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _promptController.text = data['prompt'] ?? '';
            _currentVersion = data['version'] ?? '1.0';
            _isLoading = false;
          });
        }
      } else {
        // Create initial document if it doesn't exist
        await _createInitialPrompt();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prompt: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUsageData() async {
    try {
      final analytics = await DeepSeekApi.getUsageAnalytics();
      if (mounted) {
        setState(() {
          _currentMonthUsage = analytics['current_month'];
          _totalUsage = analytics['total_usage'];
          _monthlyHistory = analytics['monthly_history'];
          _isLoadingUsage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsage = false);
      }
    }
  }

  Future<void> _createInitialPrompt() async {
    const initialPrompt = """
    You are MacroExpert, an AI assistant specialized exclusively in nutrition and macro nutrient tracking.
    Your purpose is to help users calculate, analyze, and understand the macronutrients...
    [Your initial prompt here]
    """;

    try {
      await FirebaseFirestore.instance
          .collection('chatbot_config')
          .doc('system_prompt')
          .set({
        'prompt': initialPrompt,
        'last_updated': FieldValue.serverTimestamp(),
        'version': '1.0',
      });

      if (mounted) {
        setState(() {
          _promptController.text = initialPrompt;
          _currentVersion = '1.0';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating prompt: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSystemPrompt() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Increment version number
      final newVersion = _incrementVersion(_currentVersion);

      await FirebaseFirestore.instance
          .collection('chatbot_config')
          .doc('system_prompt')
          .update({
        'prompt': _promptController.text,
        'last_updated': FieldValue.serverTimestamp(),
        'version': newVersion,
      });

      if (mounted) {
        setState(() {
          _currentVersion = newVersion;
          _isSaving = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System prompt updated successfully!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prompt: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  String _incrementVersion(String currentVersion) {
    try {
      final parts = currentVersion.split('.');
      final minor = int.parse(parts.last) + 1;
      return '${parts.sublist(0, parts.length - 1).join('.')}.$minor';
    } catch (e) {
      return '$currentVersion.1';
    }
  }

  Future<void> _testPrompt() async {
    // You can add a test functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test functionality coming soon!')),
    );
  }

  Widget _buildUsageAnalytics() {
    if (_isLoadingUsage) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Usage Analytics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Current Month Usage
            if (_currentMonthUsage != null) ...[
              _buildUsageCard(
                'Current Month',
                _currentMonthUsage!['total_tokens'] ?? 0,
                _currentMonthUsage!['cost'] ?? 0.0,
                _currentMonthUsage!['request_count'] ?? 0,
              ),
              const SizedBox(height: 12),
            ],

            // Total Usage
            if (_totalUsage != null) ...[
              _buildUsageCard(
                'All Time',
                _totalUsage!['total_tokens'] ?? 0,
                _totalUsage!['total_cost'] ?? 0.0,
                _totalUsage!['total_requests'] ?? 0,
              ),
              const SizedBox(height: 16),
            ],

            // Monthly History Bar Chart
            if (_monthlyHistory.isNotEmpty) ...[
              const Text(
                'Monthly Token Usage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildMonthlyBarChart(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    if (_monthlyHistory.isEmpty) {
      return Container(
        height: 200,
        child: const Center(
          child: Text(
            'No usage data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Sort months chronologically
    final sortedMonths = _sortMonthsChronologically(_monthlyHistory);

    // Find the maximum token value for scaling
    final maxTokens = sortedMonths
        .map((month) => (month['total_tokens'] ?? 0) as int)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      height: 200, // Fixed container height
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Chart title and legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Token Usage',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tokens (K)',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bar chart with fixed height to prevent overflow
          Container(
            height: 120, // Fixed height for the chart area
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: sortedMonths.asMap().entries.map((entry) {
                final index = entry.key;
                final monthData = entry.value;
                final tokens = (monthData['total_tokens'] ?? 0) as int;
                final monthName = _getShortMonthName(monthData['month']);
                final heightPercentage =
                    maxTokens > 0 ? (tokens / maxTokens) : 0;

                // Calculate bar height with maximum of 100px to prevent overflow
                final maxBarHeight = 100.0;
                final barHeight = maxBarHeight * heightPercentage;

                return Expanded(
                  // Use Expanded to distribute space evenly
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bar with token label
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryColor.withOpacity(0.8),
                                AppColors.primaryColor,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (barHeight >
                                  20) // Only show label if bar is tall enough
                                Positioned(
                                  top: 4,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    '${(tokens / 1000).toStringAsFixed(0)}K',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Month label
                        Text(
                          monthName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to sort months chronologically
  List<Map<String, dynamic>> _sortMonthsChronologically(
      List<Map<String, dynamic>> months) {
    try {
      // Parse and sort months
      final sorted = List<Map<String, dynamic>>.from(months)
        ..sort((a, b) {
          final dateA = _parseMonthString(a['month']);
          final dateB = _parseMonthString(b['month']);
          return dateA.compareTo(dateB);
        });

      return sorted;
    } catch (e) {
      // Fallback: return original list if parsing fails
      return months;
    }
  }

// Helper method to parse month strings into DateTime objects
  DateTime _parseMonthString(String monthString) {
    try {
      // Try different date formats
      final formats = [
        'yyyy-MM', // "2024-01"
        'MMM yyyy', // "Jan 2024"
        'MMMM yyyy', // "January 2024"
        'MM-yyyy', // "01-2024"
      ];

      for (final format in formats) {
        try {
          final inputFormat = DateFormat(format);
          final date = inputFormat.parse(monthString);
          return date;
        } catch (e) {
          continue;
        }
      }

      // If all parsing fails, return a distant past date
      return DateTime(1970);
    } catch (e) {
      return DateTime(1970);
    }
  }

  String _getShortMonthName(String monthString) {
    try {
      final date = _parseMonthString(monthString);
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return monthNames[date.month - 1];
    } catch (e) {
      // Fallback: return first 3 characters
      return monthString.length >= 3
          ? monthString.substring(0, 3)
          : monthString;
    }
  }

  Widget _buildHistoryItem(Map<String, dynamic> monthData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            monthData['month'],
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            '${((monthData['total_tokens'] ?? 0) / 1000).toStringAsFixed(0)}K tokens',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          Text(
            '\$${(monthData['cost'] ?? 0.0).toStringAsFixed(3)}',
            style: TextStyle(color: Colors.green[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard(String title, int tokens, double cost, int requests) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$requests requests',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(tokens / 1000).toStringAsFixed(1)}K tokens',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${cost.toStringAsFixed(4)}',
                style: TextStyle(
                  color: Colors.green[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
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
            // Usage Analytics Section
            _buildUsageAnalytics(),
            const SizedBox(height: 24),
            const Text(
              'Prompt Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version: $_currentVersion',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Card(
                      color: Colors.grey[850],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'System Prompt',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _promptController,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Monospace',
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Character count: ${_promptController.text.length}',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSystemPrompt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            textStyle: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
