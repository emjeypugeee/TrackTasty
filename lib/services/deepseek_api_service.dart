import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DeepSeekApi {
  // Updated URL for OpenRouter
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  static Future<String> getChatResponse({
    required String prompt,
    required List<Map<String, String>> history,
    double temperature = 0.7,
  }) async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null) throw Exception('OpenRouter API key not found');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-chat-v3-0324:free",
          "messages": [
            ...history
                .map((msg) => {"role": msg["role"], "content": msg["content"]}),
            {"role": "user", "content": prompt},
          ],
          "temperature": temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception(
            'OpenRouter Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // Backward compatibility
  static Future<String> getResponse(String prompt) async {
    return getChatResponse(
      prompt: prompt,
      history: [],
    );
  }
}
