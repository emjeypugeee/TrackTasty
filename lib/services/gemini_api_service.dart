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

  // Method to analyze a food image from a file
  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    // Add API key to URL
    var url = Uri.parse('$baseUrl?key=$apiKey');

    // Read image as bytes and convert to base64
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    // Create the request body according to Gemini API format
    Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this image. Follow these rules exactly:\n\n"
                  "CASE 1: If the image contains FOOD (actual food items, meals, or dishes):\n"
                  "Provide exactly 5 meal or drink suggestions in JSON format only. Use this exact format for each meal:\n"
                  "[\n"
                  "  {\n"
                  "    \"meal_type\": \"suggestion\",\n"
                  "    \"mealorfood_name\": \"Meal Name Here\",\n"
                  "    \"serving_size\": \"Portion description\",\n"
                  "    \"calories\": 500,\n"
                  "    \"protein\": 30,\n"
                  "    \"carbs\": 40,\n"
                  "    \"fat\": 15\n"
                  "  }\n"
                  "]\n\n"
                  "CASE 2: If the image contains a NUTRITION FACTS LABEL or NUTRITIONAL INFORMATION:\n"
                  "Extract the nutritional information and create ONE meal suggestion based on the label. Use this exact format:\n"
                  "[\n"
                  "  {\n"
                  "    \"meal_type\": \"suggestion\",\n"
                  "    \"mealorfood_name\": \"[Product Name from label or estimated name]\",\n"
                  "    \"serving_size\": \"[Serving Size from label]\",\n"
                  "    \"calories\": [Calories from label],\n"
                  "    \"protein\": [Protein in grams from label],\n"
                  "    \"carbs\": [Carbohydrates in grams from label],\n"
                  "    \"fat\": [Total Fat in grams from label]\n"
                  "  }\n"
                  "]\n"
                  "If any value is missing from the label, estimate it reasonably based on similar products.\n\n"
                  "CASE 3: If the image does NOT contain food or nutrition labels:\n"
                  "Return this exact JSON: {\"is_food\": false, \"message\": \"No food detected\"}\n\n"
                  "Return ONLY JSON. No additional text, explanations, or markdown formatting."
            },
            {
              "inline_data": {"mime_type": "image/jpeg", "data": base64Image}
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1, // Lower temperature for more consistent JSON
        "topP": 0.8,
        "topK": 40
      }
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

  // Method to parse the API response and extract the JSON data
  List<dynamic>? parseNutritionResponse(Map<String, dynamic> response) {
    try {
      // Navigate through the response structure to find the text content
      final candidates = response['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        if (content != null) {
          final parts = content['parts'];
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'];
            if (text != null) {
              // Clean the text - remove any markdown code blocks
              String cleanText =
                  text.replaceAll('```json', '').replaceAll('```', '').trim();

              // Try to parse the JSON
              dynamic parsedJson = jsonDecode(cleanText);

              // Handle different response formats
              if (parsedJson is Map<String, dynamic>) {
                // Case 3: No food detected
                if (parsedJson['is_food'] == false) {
                  return null;
                }
                // Convert single map to list for consistency
                return [parsedJson];
              } else if (parsedJson is List<dynamic>) {
                // Cases 1 & 2: Food suggestions or nutrition label data
                return parsedJson;
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing nutrition response: $e');
      debugPrint('Response text was: ${response.toString()}');
      return null;
    }
  }

  // Enhanced method that returns structured data
  Future<Map<String, dynamic>?> analyzeImageWithStructuredData() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) return null;

      final File imageFile = File(image.path);
      final analysisResult = await analyzeFoodImage(imageFile);
      final parsedData = parseNutritionResponse(analysisResult);

      return {
        'file': imageFile,
        'filePath': image.path,
        'analysis': analysisResult,
        'parsedData': parsedData,
        'isNutritionLabel': parsedData != null &&
            parsedData.isNotEmpty &&
            parsedData[0]['meal_type'] == 'nutrition_label',
        'isFoodSuggestion': parsedData != null &&
            parsedData.isNotEmpty &&
            parsedData[0]['meal_type'] == 'suggestion',
        'isNoFood': parsedData == null
      };
    } catch (e) {
      debugPrint('Error with structured image analysis: $e');
      rethrow;
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
      final parsedData = parseNutritionResponse(analysisResult);

      return {
        'file': imageFile,
        'analysis': analysisResult,
        'parsedData': parsedData,
        'filePath': image.path,
      };
    } catch (e) {
      debugPrint('Error with gallery analysis: $e');
      rethrow;
    }
  }
}
