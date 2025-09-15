import 'package:fitness/models/user_data_models.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RegistrationDataProvider with ChangeNotifier {
  static const String _prefsKey = 'user_registration_data';

  UserRegistrationData _userData = UserRegistrationData();
  UserRegistrationData get userData => _userData;

  RegistrationDataProvider() {
    loadFromPreferences();
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_userData.toMap());
      await prefs.setString(_prefsKey, jsonString);
      debugPrint('Data saved to SharedPreferences: $jsonString');
    } catch (e) {
      debugPrint('Error saving to preferences: $e');
    }
  }

  Future<void> loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final map = Map<String, dynamic>.from(json.decode(jsonString));
        _userData = UserRegistrationData.fromMap(map);
        debugPrint('Data loaded from SharedPreferences: $map');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading from preferences: $e');
    }
  }

  void updateUserData(UserRegistrationData newData) {
    _userData = newData;
    _saveToPreferences();
    notifyListeners();
  }

  void reset() {
    _userData = UserRegistrationData();
    _saveToPreferences();
    notifyListeners();
  }

  void updateBasicInfo({String? username, int? age, String? gender}) {
    if (username != null) _userData.username = username;
    if (age != null) _userData.age = age;
    if (gender != null) _userData.gender = gender;
    _saveToPreferences();
    notifyListeners();
  }

  void updateActivityLevel(String activityLevel) {
    _userData.activityLevel = activityLevel;
    _saveToPreferences();
    notifyListeners();
  }

  void updateGoal(String goal) {
    _userData.goal = goal;
    _saveToPreferences();
    notifyListeners();
  }

  void updateBodyMetrics({
    double? height,
    double? weight,
    double? goalWeight,
    bool? isMetric,
  }) {
    if (height != null) _userData.height = height;
    if (weight != null) _userData.weight = weight;
    if (goalWeight != null) _userData.goalWeight = goalWeight;
    if (isMetric != null) {
      _userData.measurementSystem = isMetric ? 'Metric' : 'US';
    }
    _saveToPreferences();
    notifyListeners();
  }

  void updateDietaryPreference(String dietaryPreference) {
    _userData.dietaryPreference = dietaryPreference;
    _saveToPreferences();
    notifyListeners();
  }

  void updateAllergies(List<String> allergies) {
    _userData.allergies = allergies;
    _saveToPreferences();
    notifyListeners();
  }

  void updateMacros({
    required double dailyCalories,
    required double carbsPercentage,
    required double fatsPercentage,
    required double proteinPercentage,
    required double carbsGram,
    required double fatsGram,
    required double proteinGram,
  }) {
    _userData.dailyCalories = dailyCalories;
    _userData.carbsPercentage = carbsPercentage;
    _userData.fatsPercentage = fatsPercentage;
    _userData.proteinPercentage = proteinPercentage;
    _userData.carbsGram = carbsGram;
    _userData.fatsGram = fatsGram;
    _userData.proteinGram = proteinGram;
    _saveToPreferences();
    notifyListeners();
  }

  void updateEmailPassword({String? email, String? password}) {
    if (email != null) _userData.email = email;
    if (password != null) _userData.password = password;
    _saveToPreferences();
    notifyListeners();
  }
}
