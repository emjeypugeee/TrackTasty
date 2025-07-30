import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DeepSeekApi {
  static const String _apiUrl = "https://api.deepseek.com/v1/chat/completions";

  // NEW: Enhanced version with conversation history
  static Future<String> getChatResponse({
    required String prompt,
    required List<Map<String, String>> history,
    double temperature = 0.7,
  }) async {
    try {
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
      if (apiKey == null) throw Exception('API key not configured');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "deepseek-chat",
          "messages": [
            ...history,
            {"role": "user", "content": prompt}
          ],
          "temperature": temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // OLD: Keep this for backward compatibility
  static Future<String> getResponse(String prompt) async {
    return getChatResponse(
      prompt: prompt,
      history: [], // Empty history for single messages
    );
  }
}
