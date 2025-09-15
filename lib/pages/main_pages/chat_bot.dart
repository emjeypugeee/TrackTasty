import 'dart:async';
import 'dart:convert';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/main_screen_widgets/chat_bot_widgets/meal_suggestion_container.dart';
import 'package:flutter/material.dart';
import 'package:fitness/services/deepseek_api_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  Map<String, dynamic>? _currentUserData;
  static const String _chatStorageKey = 'chatbot_conversation';
  bool _showResetButton = false;
  bool isMetric = false;

  // Nutrition data state
  Map<String, dynamic>? _nutritionData;
  Map<String, dynamic>? _userGoals;

  @override
  bool get wantKeepAlive => true; // Changed to true to preserve state

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNutritionData();
    _loadUserGoals();
    _loadConversationHistory();

    _scrollController.addListener(() {
      // Check if the user is at the very bottom of the screen
      final atBottom = _scrollController.offset >=
          _scrollController.position.maxScrollExtent;

      // Check if the user has scrolled up from the bottom
      final hasScrolledUp =
          _scrollController.offset < _scrollController.position.maxScrollExtent;

      // The buttons should be visible when the user has scrolled up from the bottom, and hidden when they are at the bottom.
      final shouldShowButtons = hasScrolledUp;

      if (shouldShowButtons != _showResetButton) {
        setState(() {
          _showResetButton = shouldShowButtons;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Load saved conversation from local storage
  Future<void> _loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedConversation = prefs.getString(_chatStorageKey);

      if (savedConversation != null) {
        final List<dynamic> decodedMessages = jsonDecode(savedConversation);
        setState(() {
          _messages.addAll(
              decodedMessages.map((msg) => Map<String, dynamic>.from(msg)));
        });

        // Scroll to bottom after loading messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        // If no saved conversation, add welcome message
        _addWelcomeMessage();
      }
    } catch (e) {
      debugPrint('ERROR LOADING CONVERSATION: $e');
      _addWelcomeMessage();
    }
  }

  // Save conversation to local storage
  Future<void> _saveConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chatStorageKey, jsonEncode(_messages));
    } catch (e) {
      debugPrint('ERROR SAVING CONVERSATION: $e');
    }
  }

  // Reset conversation but keep the MacroExpert introduction
  Future<void> _resetConversation() async {
    // Find the MacroExpert introduction message
    final introMessageIndex = _messages.indexWhere((msg) =>
        msg["role"] == "assistant" &&
        (msg["content"] as String).contains("Macro Tracking Assistant"));

    // Keep only the introduction message if found
    if (introMessageIndex != -1) {
      final introMessage = _messages[introMessageIndex];
      setState(() {
        _messages.clear();
        _messages.add(introMessage);
      });
    } else {
      // If no intro found, clear all and add welcome message
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
    }

    // Clear from storage and save the new state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatStorageKey, jsonEncode(_messages));

    // Scroll to top to show the intro message
    _scrollToTop();
  }

  void _loadUserData() {
    final userProvider = context.read<UserProvider>();
    _currentUserData = userProvider.userData;
    debugPrint("USER DATA LOADED: $_currentUserData");
  }

  // Load user's nutrition goals
  Future<void> _loadUserGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userGoals = {
            'calorieGoal': _convertToInt(userDoc.data()?['dailyCalories']),
            'proteinGoal': _convertToInt(userDoc.data()?['proteinGram']),
            'carbsGoal': _convertToInt(userDoc.data()?['carbsGram']),
            'fatGoal': _convertToInt(userDoc.data()?['fatsGram']),
          };
        });
        debugPrint("USER GOALS LOADED: $_userGoals");
      }
    } catch (e) {
      debugPrint('ERROR LOADING USER GOALS: $e');
    }
  }

  // Load today's nutrition data
  Future<void> _loadNutritionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final foodLogId = '${user.uid}_${today.year}-${today.month}-${today.day}';

    try {
      final foodLogDoc = await FirebaseFirestore.instance
          .collection('food_logs')
          .doc(foodLogId)
          .get();

      if (foodLogDoc.exists) {
        setState(() {
          _nutritionData = {
            'totalCalories': _convertToInt(foodLogDoc.data()?['totalCalories']),
            'totalProtein': _convertToInt(foodLogDoc.data()?['totalProtein']),
            'totalCarbs': _convertToInt(foodLogDoc.data()?['totalCarbs']),
            'totalFat': _convertToInt(foodLogDoc.data()?['totalFat']),
          };
        });
        debugPrint("NUTRITION DATA LOADED: $_nutritionData");
      } else {
        setState(() {
          _nutritionData = {
            'totalCalories': 0,
            'totalProtein': 0,
            'totalCarbs': 0,
            'totalFat': 0,
          };
        });
        debugPrint("NO NUTRITION DATA FOUND, USING DEFAULT: $_nutritionData");
      }
    } catch (e) {
      debugPrint('ERROR LOADING NUTRITION DATA: $e');
      setState(() {
        _nutritionData = {
          'totalCalories': 0,
          'totalProtein': 0,
          'totalCarbs': 0,
          'totalFat': 0,
        };
      });
    }
  }

  // Helper function to convert any value to int
  int _convertToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _addWelcomeMessage() {
    _messages.add({
      "role": "assistant",
      "content": "👋 Hi! I'm your Macro Tracking Assistant!\n\n"
          "I can help you with:\n"
          "• Calculating your ideal macros\n"
          "• Tracking meals and nutrients\n"
          "• Planning meals for your goals\n"
          "• Understanding food nutrition\n\n"
          "Try asking:\n"
          "• \"Calculate my macros for weight loss\"\n"
          "• \"What's the protein in 200g chicken?\"\n"
          "• \"Plan a high-protein breakfast\""
    });

    // Save the conversation after adding welcome message
    _saveConversation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _refreshUserData() async {
    setState(() => _isLoading = true);
    debugPrint("REFRESHING USER DATA...");

    // Simulate a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    final userProvider = context.read<UserProvider>();
    final newUserData = userProvider.userData;

    // Reload nutrition data and goals
    await _loadNutritionData();
    await _loadUserGoals();

    setState(() {
      _currentUserData = newUserData;
      _isLoading = false;
    });

    debugPrint("USER DATA REFRESHED: $_currentUserData");

    // Show confirmation message
    _showRefreshConfirmation();
  }

  void _showRefreshConfirmation() {
    final newUserData = _currentUserData;
    if (newUserData != null) {
      // Calculate remaining macros
      final remainingCalories = (_userGoals?['calorieGoal'] ?? 2000) -
          (_nutritionData?['totalCalories'] ?? 0);
      final remainingProtein = (_userGoals?['proteinGoal'] ?? 100) -
          (_nutritionData?['totalProtein'] ?? 0);
      final remainingCarbs = (_userGoals?['carbsGoal'] ?? 250) -
          (_nutritionData?['totalCarbs'] ?? 0);
      final remainingFat =
          (_userGoals?['fatGoal'] ?? 70) - (_nutritionData?['totalFat'] ?? 0);
      isMetric = newUserData['measurementSystem'] == "Metric";

      isMetric = newUserData['measurementSystem'] == "Metric";

// Helper variables for unit conversion
      final weightUnit = isMetric ? 'kg' : 'lbs';
      final heightUnit = isMetric ? 'cm' : 'inches';

      _messages.add({
        "role": "system",
        "content": "🔄 Profile updated! I now know:\n"
            "• Age: ${newUserData['age']?.toString() ?? 'Not set'}\n"
            "• Weight: ${newUserData['weight']?.toString() ?? 'Not set'} $weightUnit\n"
            "• Height: ${newUserData['height']?.toString() ?? 'Not set'} $heightUnit\n"
            "• Goal: ${newUserData['goal']?.toString() ?? 'Not set'}\n"
            "• Dietary Preference: ${newUserData['dietaryPreference']?.toString() ?? 'None'}\n"
            "• Allergies: ${newUserData['allergies']?.toString() ?? "None"}\n\n"
            "📊 Today's Progress:\n"
            "• Calories: ${_nutritionData?['totalCalories'] ?? 0}/${_userGoals?['calorieGoal'] ?? 2000} "
            "(${remainingCalories > 0 ? '$remainingCalories remaining' : '${-remainingCalories} over'})\n"
            "• Protein: ${_nutritionData?['totalProtein'] ?? 0}/${_userGoals?['proteinGoal'] ?? 100}g "
            "(${remainingProtein > 0 ? '$remainingProtein g remaining' : '${-remainingProtein}g over'})\n"
            "• Carbs: ${_nutritionData?['totalCarbs'] ?? 0}/${_userGoals?['carbsGoal'] ?? 250}g "
            "(${remainingCarbs > 0 ? '$remainingCarbs g remaining' : '${-remainingCarbs}g over'})\n"
            "• Fat: ${_nutritionData?['totalFat'] ?? 0}/${_userGoals?['fatGoal'] ?? 70}g "
            "(${remainingFat > 0 ? '$remainingFat g remaining' : '${-remainingFat}g over'})"
      });

      // Save the conversation after adding system message
      _saveConversation();

      _scrollToBottom();
    }
  }

  // Parsing JSON response
  Map<String, dynamic> _parseMixedResponse(String content) {
    try {
      // First, try to parse the entire content as JSON
      final jsonData = jsonDecode(content);
      if (jsonData is List) {
        return {
          'meals': jsonData.whereType<Map<String, dynamic>>().toList(),
          'text': ''
        };
      }
      if (jsonData is Map<String, dynamic>) {
        return {
          'meals': [jsonData],
          'text': ''
        };
      }
    } catch (e) {
      // If not pure JSON, look for JSON objects within text
      final jsonPattern = r'\{.*?"meal_type".*?"suggestion".*?\}';
      final matches = RegExp(jsonPattern, multiLine: true).allMatches(content);

      if (matches.isNotEmpty) {
        final meals = <Map<String, dynamic>>[];
        var remainingText = content;

        for (final match in matches) {
          try {
            final jsonStr = match.group(0);
            if (jsonStr != null) {
              final meal = jsonDecode(jsonStr) as Map<String, dynamic>;
              meals.add(meal);
              remainingText = remainingText.replaceAll(jsonStr, '').trim();
            }
          } catch (e) {
            // Skip invalid JSON matches
          }
        }

        return {
          'meals': meals,
          'text': remainingText.isNotEmpty ? remainingText : ''
        };
      }
    }

    return {'meals': [], 'text': content};
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty || _isLoading) return;

    // Debug print for user input
    debugPrint("USER INPUT: \"$userMessage\"");

    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _messageController.clear();
      _isLoading = true;
    });

    // Save the conversation after adding user message
    _saveConversation();

    try {
      // Debug print for API request data
      debugPrint("API REQUEST DATA:");
      debugPrint(
          "- Username: ${_currentUserData?['username']?.toString() ?? 'Guest'}");
      debugPrint("- Age: ${_currentUserData?['age']?.toString() ?? '25'}");
      debugPrint(
          "- Weight: ${_currentUserData?['weight']?.toString() ?? '65'}");
      debugPrint(
          "- Height: ${_currentUserData?['height']?.toString() ?? '170'}");
      debugPrint(
          "- Goal: ${_currentUserData?['goal']?.toString() ?? 'maintenance'}");
      debugPrint(
          "- Calories: ${_nutritionData?['totalCalories'] ?? 0}/${_userGoals?['calorieGoal'] ?? 2000}");
      debugPrint(
          "- Protein: ${_nutritionData?['totalProtein'] ?? 0}/${_userGoals?['proteinGoal'] ?? 100}g");
      debugPrint(
          "- Carbs: ${_nutritionData?['totalCarbs'] ?? 0}/${_userGoals?['carbsGoal'] ?? 250}g");
      debugPrint(
          "- Fat: ${_nutritionData?['totalFat'] ?? 0}/${_userGoals?['fatGoal'] ?? 70}g");

      // Convert history to the correct type (Map<String, String>)
      final List<Map<String, String>> history = _messages
          .sublist(1, _messages.length - 1)
          .where((msg) =>
              msg["role"] != "meal_suggestion" &&
              msg["role"] != "system" &&
              msg["role"] != "error")
          .map((msg) => {
                "role": msg["role"] as String,
                "content": msg["content"] is String
                    ? msg["content"] as String
                    : msg["content"].toString(),
              })
          .toList();

      final aiMessage = await DeepSeekApi.getChatResponse(
        prompt: userMessage,
        username: _currentUserData?['username']?.toString() ?? 'Guest',
        age: _currentUserData?['age']?.toString() ?? '25',
        allergies: List<String>.from(_currentUserData?['allergies'] ?? []),
        weight: _currentUserData?['weight']?.toString() ?? '65',
        height: _currentUserData?['height']?.toString() ?? '170',
        goal: _currentUserData?['goal']?.toString() ?? 'maintenance',
        goalWeight: _currentUserData?['goalWeight']?.toString() ?? '0',
        gender: _currentUserData?['gender']?.toString() ?? 'prefer not to say',
        dietaryPreference:
            _currentUserData?['dietaryPreference']?.toString() ?? 'none',
        totalCalories: _nutritionData?['totalCalories'] ?? 0,
        totalProtein: _nutritionData?['totalProtein'] ?? 0,
        totalCarbs: _nutritionData?['totalCarbs'] ?? 0,
        totalFat: _nutritionData?['totalFat'] ?? 0,
        calorieGoal: _userGoals?['calorieGoal'] ?? 2000,
        proteinGoal: _userGoals?['proteinGoal'] ?? 100,
        carbsGoal: _userGoals?['carbsGoal'] ?? 250,
        fatGoal: _userGoals?['fatGoal'] ?? 70,
      ).timeout(const Duration(seconds: 30));

      // Parse for JSON meals + normal text
      final parsedResponse = _parseMixedResponse(aiMessage);

      // Debug print for chatbot output
      debugPrint("PARSED RESPONSE: ${parsedResponse['meals'].length} meals, "
          "text: '${parsedResponse['text']}'");

      if (parsedResponse['meals'].isNotEmpty) {
        for (final meal in parsedResponse['meals']) {
          setState(() {
            _messages.add({
              "role": "meal_suggestion",
              "content": meal,
            });
          });
        }
      }

      // Add text response if exists
      if (parsedResponse['text'].isNotEmpty) {
        setState(() {
          _messages
              .add({"role": "assistant", "content": parsedResponse['text']});
        });
      }

      // Save the conversation after adding AI response
      _saveConversation();
    } catch (e) {
      // Debug print for error
      debugPrint("API ERROR: $e");

      String errorMessage;
      if (e is TimeoutException) {
        errorMessage = "Request timed out. Please try again.";
        debugPrint("ERROR TYPE: TimeoutException");
      } else if (e.toString().contains("401") || e.toString().contains("403")) {
        errorMessage = "Authentication failed. Please check your API key.";
        debugPrint("ERROR TYPE: Authentication Error");
      } else if (e.toString().contains("429")) {
        errorMessage = "Too many requests. Please wait a moment.";
        debugPrint("ERROR TYPE: Rate Limit Error");
      } else if (e.toString().contains("500") ||
          e.toString().contains("502") ||
          e.toString().contains("503")) {
        errorMessage = "Server error. Please try again later.";
        debugPrint("ERROR TYPE: Server Error");
      } else {
        errorMessage =
            "Sorry, I couldn't process your request. Please try again.";
        debugPrint("ERROR TYPE: Unknown Error");
      }

      debugPrint("ERROR MESSAGE DISPLAYED TO USER: \"$errorMessage\"");

      setState(() {
        _messages.add({
          "role": "error",
          "content": errorMessage,
        });
      });

      // Save the conversation after adding error message
      _saveConversation();
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Removed the App Bar section
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message["role"] == "user";
                    final isError = message["role"] == "error";
                    final isSystem = message["role"] == "system";
                    final isMealSuggestion =
                        message["role"] == "meal_suggestion";

                    if (isMealSuggestion) {
                      final mealData =
                          message["content"] as Map<String, dynamic>;
                      return Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85,
                        ),
                        child: MealSuggestionContainer(
                          mealData: mealData,
                          onAdded: _refreshUserData,
                        ),
                      );
                    }

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isError
                              ? Colors.red[900]
                              : isSystem
                                  ? Colors.green[800]
                                  : isUser
                                      ? Colors.blue[800]
                                      : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message["content"] as String,
                          style: TextStyle(
                            color: isError
                                ? Colors.red[200]
                                : isSystem
                                    ? Colors.green[100]
                                    : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Removed the Reload User Data button from the bottom
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating buttons that appear when scrolling up (not at bottom)
          AnimatedOpacity(
            opacity: _showResetButton
                ? 1.0
                : 0.0, // Animate opacity based on visibility
            duration: const Duration(milliseconds: 300), // Animation duration
            curve: Curves.easeInOut, // Smooth easing curve
            child: Visibility(
              visible:
                  _showResetButton, // Ensure the buttons are only visible when needed
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reload User Data Button
                        GestureDetector(
                          onTap: _isLoading ? null : _refreshUserData,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[800]!.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue[700]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isLoading)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue,
                                    ),
                                  )
                                else
                                  Icon(Icons.refresh,
                                      size: 14, color: Colors.blue[300]),
                                const SizedBox(width: 4),
                                Text(
                                  _isLoading ? 'Reloading...' : 'Reload Data',
                                  style: TextStyle(
                                    color: _isLoading
                                        ? Colors.grey[400]
                                        : Colors.blue[300],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reset Chat Button
                        GestureDetector(
                          onTap: _resetConversation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[800]!.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red[700]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restart_alt,
                                    size: 14, color: Colors.red[300]),
                                const SizedBox(width: 4),
                                Text(
                                  'Reset Chat',
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
