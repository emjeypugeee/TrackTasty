import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fitness/services/deepseek_api_service.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _messages.add({
      "role": "assistant",
      "content": "👋 Hi! I’m your Fitness Assistant. Ask me anything!\n\n"
          "Try these examples:\n"
          "• \"Suggest a high-protein breakfast\"\n"
          "• \"What’s a good beginner workout?\"\n"
          "• \"Help me track my calories.\""
    });
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _messageController.clear();
      _isLoading = true;
      _isFirstLoad = false;
    });

    try {
      final aiMessage = await DeepSeekApi.getChatResponse(
        prompt: userMessage,
        history: _messages.sublist(
            1, _messages.length - 1), // Skip the initial welcome message
      ).timeout(const Duration(seconds: 30)); // Add timeout

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
        errorMessage =
            "Sorry, I couldn't process your request. Please try again.";
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                if (_isFirstLoad && index == 0) return const SizedBox.shrink();
                final message = _messages[index];
                final isUser = message["role"] == "user";
                final isError = message["role"] == "error";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
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
