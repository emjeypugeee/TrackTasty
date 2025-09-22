import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class GeminiApiService {
  final String apiKey = dotenv.env['GEMINI_API_KEY']!;
  // Updated endpoint - try different model names
  static const String baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent";

  // Alternative model names to try:
  // - "gemini-pro"
  // - "gemini-1.0-pro"
  // - "gemini-1.5-pro"
  // - "gemini-pro-vision" (if available in your region)

  // Method to analyze a food image from a file
  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    // Add API key to URL
    var url = Uri.parse('$baseUrl?key=$apiKey');

    // Read image as bytes and convert to base64
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    // Create the request body according to Gemini API format
    // In gemini_api_service.dart, update the analyzeFoodImage method
    Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this image. If it contains food, provide exactly 5 meal or drink suggestions in JSON format only. "
                  "Use this exact format for each meal:\n"
                  "  \"meal_type\": \"suggestion\",\n"
                  "  \"mealorfood_name\": \"Meal Name Here\",\n"
                  "  \"serving_size\": \"Portion description\",\n"
                  "  \"calories\": 500,\n"
                  "  \"protein\": 30,\n"
                  "  \"carbs\": 40,\n"
                  "  \"fat\": 15\n"
                  "If the image does NOT contain food, return this exact JSON: {\"is_food\": false, \"message\": \"No food detected\"}. "
                  "Return ONLY JSON. No additional text or explanations."
            },
            {
              "inline_data": {"mime_type": "image/jpeg", "data": base64Image}
            }
          ]
        }
      ],
      "generationConfig": {"temperature": 0.4, "topP": 0.8, "topK": 40}
    };

    // Make the POST request
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to analyze image. Status code: ${response.statusCode}. Response: ${response.body}');
    }
  }

  // Check available models
  Future<List<dynamic>> getAvailableModels() async {
    var url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['models'];
    } else {
      throw Exception('Failed to fetch models: ${response.statusCode}');
    }
  }

  // Method to pick and analyze image from gallery
  Future<Map<String, dynamic>?> analyzeImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Pick an image from gallery
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) {
        return null; // User cancelled the picker
      }

      // Convert XFile to File
      final File imageFile = File(image.path);

      // Analyze the image
      return await analyzeFoodImage(imageFile);
    } catch (e) {
      debugPrint('Error picking/analyzing image from gallery: $e');
      throw Exception('Failed to pick or analyze image from gallery: $e');
    }
  }

  // Alternative method that returns both the file and analysis result
  Future<Map<String, dynamic>?> analyzeGalleryImageWithFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      final File imageFile = File(image.path);
      final analysisResult = await analyzeFoodImage(imageFile);

      return {
        'file': imageFile,
        'analysis': analysisResult,
        'filePath': image.path,
      };
    } catch (e) {
      debugPrint('Error with gallery analysis: $e');
      rethrow;
    }
  }
}
