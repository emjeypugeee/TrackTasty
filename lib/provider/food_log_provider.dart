import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/model/food_item.dart';
import 'package:fitness/services/gemini_api_service.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/camera_screen/food_analysis_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<FoodItem> _suggestedFoods = [];

  // Create GlobalKey for showing dialogs without context issues
  final GlobalKey<State> _key = GlobalKey<State>();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<String?> takePicture() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        debugPrint('Camera controller is not initialized');
        return null;
      }

      debugPrint('Taking picture...');
      final XFile picture = await _controller!.takePicture();
      debugPrint('Picture captured at: ${picture.path}');

      final Directory extDir = await getTemporaryDirectory();
      final String dirPath = '${extDir.path}/Pictures/fitness_app';
      final Directory directory = Directory(dirPath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
        debugPrint('Created directory: $dirPath');
      }

      final String filePath =
          join(dirPath, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      debugPrint('Saving to: $filePath');

      await picture.saveTo(filePath);
      debugPrint('Image saved successfully');

      return filePath;
    } catch (e, stackTrace) {
      debugPrint('Error taking picture: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _analyzeFoodImage(String imagePath) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _suggestedFoods = []; // Clear previous suggestions
    });

    try {
      final File imageFile = File(imagePath);
      final GeminiApiService apiService = GeminiApiService();

      debugPrint('Calling Gemini API...');
      final Map<String, dynamic> analysisResult =
          await apiService.analyzeFoodImage(imageFile);
      debugPrint('Full API response: $analysisResult');

      if (analysisResult.containsKey('candidates') &&
          analysisResult['candidates'] is List &&
          analysisResult['candidates'].isNotEmpty) {
        final candidate = analysisResult['candidates'][0];
        if (candidate.containsKey('content') &&
            candidate['content'].containsKey('parts') &&
            candidate['content']['parts'] is List &&
            candidate['content']['parts'].isNotEmpty) {
          final parts = candidate['content']['parts'];
          for (var part in parts) {
            if (part.containsKey('text')) {
              final String textResponse = part['text'];
              debugPrint('Gemini Analysis: $textResponse');

              // Parse the response to extract food suggestions
              _parseFoodSuggestions(textResponse);

              if (mounted) {
                _showAnalysisResult(textResponse);
              }
              break;
            }
          }
        }
      } else {
        debugPrint('No analysis candidates found in response');
        if (mounted) {
          _showError('No analysis results found');
        }
      }
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      if (mounted) {
        _showError('Error analyzing image: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _parseFoodSuggestions(String textResponse) {
    try {
      // Try to parse the JSON response
      // First, extract the JSON array from the text
      String jsonString = textResponse;

      // If the response contains markdown code blocks, extract the JSON
      if (textResponse.contains('```json')) {
        jsonString = textResponse.split('```json')[1].split('```')[0].trim();
      } else if (textResponse.contains('```')) {
        jsonString = textResponse.split('```')[1].split('```')[0].trim();
      }

      // Clean up the JSON string - remove trailing commas if present
      jsonString = jsonString.replaceAll(',\n}', '\n}');

      // Check if it's a single object or an array
      if (jsonString.trim().startsWith('{')) {
        // It's a single object, wrap it in an array
        jsonString = '[$jsonString]';
      }

      debugPrint('Extracted JSON: $jsonString');

      // Parse the JSON array
      List<dynamic> jsonList = jsonDecode(jsonString);
      List<FoodItem> suggestions = [];

      for (var item in jsonList) {
        if (item is Map<String, dynamic>) {
          // Extract values using different possible key names
          String mealName = item['mealorfood_name'] ??
              item['mealName'] ??
              item['name'] ??
              'Unknown Food';

          String servingSize = item['serving_size'] ??
              item['servingSize'] ??
              item['serving'] ??
              '1 serving';

          // Handle different numeric formats - convert to int
          int calories = 0;
          if (item['calories'] != null) {
            calories = (item['calories'] is int)
                ? item['calories'] as int
                : (item['calories'] is double)
                    ? (item['calories'] as double).round()
                    : int.tryParse(item['calories'].toString()) ?? 0;
          }

          int protein = 0;
          if (item['protein'] != null) {
            protein = (item['protein'] is int)
                ? item['protein'] as int
                : (item['protein'] is double)
                    ? (item['protein'] as double).round()
                    : int.tryParse(item['protein'].toString()) ?? 0;
          }

          int carbs = 0;
          if (item['carbs'] != null) {
            carbs = (item['carbs'] is int)
                ? item['carbs'] as int
                : (item['carbs'] is double)
                    ? (item['carbs'] as double).round()
                    : int.tryParse(item['carbs'].toString()) ?? 0;
          }

          int fat = 0;
          if (item['fat'] != null) {
            fat = (item['fat'] is int)
                ? item['fat'] as int
                : (item['fat'] is double)
                    ? (item['fat'] as double).round()
                    : int.tryParse(item['fat'].toString()) ?? 0;
          }

          suggestions.add(FoodItem(
            mealType: 'suggestion',
            mealName: mealName,
            servingSize: servingSize,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
          ));
        }
      }

      setState(() {
        _suggestedFoods = suggestions;
      });
    } catch (e) {
      debugPrint('Error parsing food suggestions: $e');
      // Fallback suggestions if parsing fails
      setState(() {
        _suggestedFoods = [
          FoodItem(
            mealType: 'suggestion',
            mealName: 'Classic Beef Burger',
            servingSize: '1 burger (bun, patty, toppings)',
            calories: 650,
            protein: 35,
            carbs: 45,
            fat: 38,
          ),
          FoodItem(
            mealType: 'suggestion',
            mealName: 'Grilled Chicken Sandwich',
            servingSize: '1 sandwich',
            calories: 450,
            protein: 40,
            carbs: 35,
            fat: 18,
          ),
          FoodItem(
            mealType: 'suggestion',
            mealName: 'Portobello Mushroom Burger',
            servingSize: '1 burger',
            calories: 400,
            protein: 15,
            carbs: 50,
            fat: 15,
          ),
        ];
      });
    }
  }

  Future<void> _saveFoodToLog(FoodItem food) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final foodLogId =
            '${user.uid}_${today.year}-${today.month}-${today.day}';

        // Fetch existing food log for today or create a new one
        final foodLogDoc = await FirebaseFirestore.instance
            .collection('food_logs')
            .doc(foodLogId)
            .get();

        Map<String, dynamic> foodLogData = {
          'userId': user.uid,
          'date': Timestamp.fromDate(today),
          'totalCalories': 0,
          'totalCarbs': 0,
          'totalProtein': 0,
          'totalFat': 0,
          'foods': [],
        };

        // If the document exists, update the data
        if (foodLogDoc.exists && foodLogDoc.data() != null) {
          foodLogData = foodLogDoc.data() as Map<String, dynamic>;
        }

        // Update total macros
        final calories = food.calories;
        final carbs = food.carbs;
        final protein = food.protein;
        final fat = food.fat;

        foodLogData['totalCalories'] =
            (foodLogData['totalCalories'] ?? 0) + calories;
        foodLogData['totalCarbs'] = (foodLogData['totalCarbs'] ?? 0) + carbs;
        foodLogData['totalProtein'] =
            (foodLogData['totalProtein'] ?? 0) + protein;
        foodLogData['totalFat'] = (foodLogData['totalFat'] ?? 0) + fat;

        // Add the new food item
        foodLogData['foods'].add({
          'mealName': food.mealName,
          'calories': calories,
          'carbs': carbs,
          'protein': protein,
          'fat': fat,
          'loggedTime': Timestamp.fromDate(DateTime.now()),
          'servingSize': food.servingSize,
        });

        // Save updated food log data
        await FirebaseFirestore.instance
            .collection('food_logs')
            .doc(foodLogId)
            .set(foodLogData);

        debugPrint('Saving food to log: ${food.mealName}');

        // Show success message
        ScaffoldMessenger.of(_key.currentContext!).showSnackBar(
          SnackBar(
            content: Text('${food.mealName} added to food log successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        GoRouter.of(_key.currentContext!).go('/home');
      } else {
        // User is not logged in
        ScaffoldMessenger.of(_key.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Please log in to save food items'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving food: $e');
      ScaffoldMessenger.of(_key.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Error saving food: ${e.toString()}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAnalysisResult(String result) {
    showDialog(
      context: _key.currentContext!,
      builder: (BuildContext context) {
        return FoodAnalysisDialog(
          analysisResult: result,
          mealSuggestions: _suggestedFoods,
          onAddMeal: _saveFoodToLog,
        );
      },
    );
  }

  void _showError(String error) {
    // Use Navigator.of with a context that's always available
    Navigator.of(_key.currentContext!).push(
      DialogRoute(
        context: _key.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(error),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key, // Assign the key to the Scaffold
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: AppColors.primaryText,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Food',
          style: TextStyle(color: AppColors.primaryColor),
        ),
        backgroundColor: AppColors.loginPagesBg,
      ),
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            if (_isCameraInitialized &&
                _controller != null &&
                _controller!.value.isInitialized)
              CameraPreview(_controller!),
            if (_isProcessing)
              Center(
                child: Container(
                  color: Colors.black54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing food image...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    height: 50,
                    width: 300,
                    decoration: BoxDecoration(
                      color: AppColors.containerBg,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Center food in frame',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FloatingActionButton(
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  final imagePath = await takePicture();
                                  if (imagePath != null && mounted) {
                                    debugPrint("Image path: $imagePath");
                                    await _analyzeFoodImage(imagePath);
                                  }
                                },
                          backgroundColor: _isProcessing
                              ? Colors.grey
                              : AppColors.primaryText,
                          child: _isProcessing
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : Icon(Icons.camera),
                        ),
                        Positioned(
                          right: MediaQuery.of(context).size.width * 0.2,
                          child: GestureDetector(
                            onTap: _isProcessing
                                ? null
                                : () async {
                                    if (!mounted) return;

                                    setState(() {
                                      _isProcessing = true;
                                    });

                                    try {
                                      final GeminiApiService apiService =
                                          GeminiApiService();
                                      final result = await apiService
                                          .analyzeImageFromGallery();

                                      if (result != null && mounted) {
                                        debugPrint(
                                            'Gallery analysis result: $result');
                                        if (result.containsKey('candidates')) {
                                          final candidate =
                                              result['candidates'][0];
                                          if (candidate
                                                  .containsKey('content') &&
                                              candidate['content']
                                                  .containsKey('parts')) {
                                            final parts =
                                                candidate['content']['parts'];
                                            for (var part in parts) {
                                              if (part.containsKey('text')) {
                                                final String textResponse =
                                                    part['text'];
                                                _parseFoodSuggestions(
                                                    textResponse);
                                                _showAnalysisResult(
                                                    textResponse);
                                                break;
                                              }
                                            }
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint(
                                          'Error analyzing gallery image: $e');
                                      if (mounted) {
                                        _showError(
                                            'Error analyzing gallery image: ${e.toString()}');
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isProcessing = false;
                                        });
                                      }
                                    }
                                  },
                            child: Icon(
                              Icons.photo_library,
                              color: _isProcessing ? Colors.grey : Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_isCameraInitialized)
              Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
