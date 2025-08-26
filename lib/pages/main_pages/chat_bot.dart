import 'dart:async';

import 'package:fitness/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:fitness/services/deepseek_api_service.dart';
import 'package:provider/provider.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty || _isLoading) return;

    //user data
    final userProvider = context.read<UserProvider>();
    final userData = userProvider.userData;

    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final aiMessage = await DeepSeekApi.getChatResponse(
        prompt: userMessage,
        history: _messages.sublist(1, _messages.length - 1),
        username: userData?['username'] ?? 'Guest',
        age: userData?['age'] ?? 'null',
        allergies: List<String>.from(userData?['allergies'] ?? []),
        weight: userData?['weight'] ?? 'null',
        height: userData?['height'] ?? 'null',
        goal: userData?['goal'] ?? 'null',
        goalWeight: userData?['goalWeight'] ?? 'null',
        gender: userData?['gender'] ?? 'null',
        dietaryPreference: userData?['dietaryPreference'] ?? 'null',
      ).timeout(const Duration(seconds: 30));

      setState(() {
        _messages.add({"role": "assistant", "content": aiMessage});
      });
    } catch (e) {
      debugPrint("API Error Details: $e");

      // More specific error messages
      String errorMessage;
      if (e is TimeoutException) {
        errorMessage = "Request timed out. Please try again.";
      } else if (e.toString().contains("401") || e.toString().contains("403")) {
        errorMessage = "Authentication failed. Please check your API key.";
      } else if (e.toString().contains("429")) {
        errorMessage = "Too many requests. Please wait a moment.";
      } else if (e.toString().contains("500") ||
          e.toString().contains("502") ||
          e.toString().contains("503")) {
        errorMessage = "Server error. Please try again later.";
      } else {
        errorMessage = "Sorry, I couldn't process your request. Please try again.";
      }

      setState(() {
        _messages.add({
          "role": "error",
          "content": errorMessage,
        });
      });
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["role"] == "user";
                final isError = message["role"] == "error";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.red[900]
                          : isUser
                              ? Colors.blue[800]
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["content"]!,
                      style: TextStyle(
                        color: isError ? Colors.red[200] : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
    );
  }
}
