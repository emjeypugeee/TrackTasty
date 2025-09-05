import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// In your DeepSeekApiService.dart file
class DeepSeekApi {
  static final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  static Future<String> getChatResponse(
      {required String prompt,
      required List<Map<String, String>> history,
      required String username,
      required String age,
      required String weight,
      required String height,
      required List<String> allergies,
      required String gender,
      required String dietaryPreference,
      required String goal,
      required String goalWeight}) async {
    final String systemPrompt = """
    You are MacroExpert, an AI assistant specialized exclusively in nutrition and macro nutrient tracking. 
    Your purpose is to help users calculate, analyze, and understand the macronutrients (proteins, fats, carbohydrates) and calories in their meals.

     USER PROFILE:
    - Name: $username
    - Age: $age
    - Weight: $weight
    - Height: $height
    - Gender: $gender
    - Goal: $goal
    - Goal Weight: $goalWeight
    - Dietary Preference: $dietaryPreference
    - Allergies: ${allergies.isEmpty ? 'None' : allergies.join(', ')}

    RULES:
    1. ONLY answer questions related to:
       - Macro nutrient tracking (protein, carbs, fat)
       - Calorie counting
       - Meal planning for fitness goals
       - Food nutrition information
       - Healthy eating habits
       - Supplement questions
    
    2. If asked about unrelated topics (politics, entertainment, general knowledge), respond:
       "I specialize only in nutrition and macro tracking. How can I help with your fitness nutrition questions?"
    
    3. For macro calculations:
       - Ask for weight goals (loss, maintenance, gain)
       - Calculate TDEE based on provided stats
       - Suggest macro splits based on goals
       - Provide food suggestions to hit macros

    4. Consider their dietary preferences ($dietaryPreference) and allergies when suggesting foods.
    
    5. Keep responses focused, practical, and evidence-based.

    6. Avoid using these signs " # and * "
    """;

    // Prepare messages with system prompt first
    final List<Map<String, String>> messages = [
      {"role": "system", "content": systemPrompt},
      ...history,
      {"role": "user", "content": prompt}
    ];

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to load response: ${response.statusCode}');
    }
  }

  // OLD: Keep this for backward compatibility
  static Future<String> getResponse(String prompt) async {
    return getChatResponse(
      prompt: prompt,
      history: [],
      username: 'Guest',
      age: '25',
      weight: '70.0',
      height: '170.0',
      allergies: [],
      gender: 'prefer not to say',
      dietaryPreference: 'none',
      goal: 'maintenance',
      goalWeight: '70.0',
    );
  }
}
