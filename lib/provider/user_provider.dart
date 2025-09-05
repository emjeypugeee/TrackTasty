import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  // Add these getters for easy access to common fields
  String get nickname => _userData?['username'] ?? 'Unknown User';
  int? get joinedDate => _userData?['dateAccountCreated'];
  String? get email => _user?.email;

  // NEW: Getters for profile fields
  int? get age {
    final value = _userData?['age'];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? get weight {
    final value = _userData?['weight'];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double? get height {
    final value = _userData?['height'];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? get gender {
    final value = _userData?['gender'];
    return value?.toString();
  }

  String? get selectedActivityLevel {
    final value = _userData?['selectedActivityLevel'];
    return value?.toString();
  }

  String? get goal {
    final value = _userData?['goal'];
    return value?.toString();
  }

  String? get measurementSystem {
    final value = _userData?['measurementSystem'];
    return value?.toString();
  }

  // Initialize user data
  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = _auth.currentUser;
      if (_user != null) {
        final doc = await _firestore.collection("Users").doc(_user?.email).get();
        if (doc.exists) {
          _userData = doc.data();
        } else {
          _userData = {};
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Update UI
    }
  }

  // NEW: Update user profile information
  Future<bool> updateUserProfile({
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
    required String goal,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('Users').doc(user.email).set({
        'age': age,
        'weight': weight,
        'height': height,
        'gender': gender,
        'selectedActivityLevel': activityLevel,
        'goal': goal,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local data immediately
      if (_userData != null) {
        _userData!['age'] = age;
        _userData!['weight'] = weight;
        _userData!['height'] = height;
        _userData!['gender'] = gender;
        _userData!['selectedActivityLevel'] = activityLevel;
        _userData!['goal'] = goal;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print("Error updating user profile: $e");
      return false;
    }
  }

  // Update nickname - FIXED VERSION
  Future<bool> updateUsername(String newUsername) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      await _firestore.collection("Users").doc(user.email).set(
        {
          'username': newUsername,
        },
        SetOptions(merge: true),
      );

      // Update local data immediately
      if (_userData != null) {
        _userData!['username'] = newUsername;
      }

      notifyListeners(); // This will rebuild widgets listening to the provider
      return true; // Success
    } catch (e) {
      print("Error updating username: $e");
      return false; // Failure
    }
  }

  Future<void> forgetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Re-throw to handle in UI
      rethrow;
    } catch (e) {
      // Handle unexpected errors
      throw Exception("Failed to send reset email: $e");
    }
  }

  // Update preferences - FIXED VERSION
  Future<bool> saveUserPreferences(String newGoalWeight, String newGoal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
          'goalWeight': newGoalWeight,
          'goal': newGoal,
        }, SetOptions(merge: true));

        // Update local data
        if (_userData != null) {
          _userData!['goalWeight'] = newGoalWeight;
          _userData!['goal'] = newGoal;
        }

        notifyListeners();
        return true; // Success
      }
      return false; // Failed
    } catch (e) {
      print("Error saving preferences: $e");
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _userData = null;
    notifyListeners(); // Reset UI to login screen
  }

  // Add this method to refresh user data from Firestore
  Future<void> refreshUserData() async {
    await fetchUserData();
  }

  // Add this method to your UserProvider class
Future<bool> updateWeight(double weight) async {
  try {
    final user = _auth.currentUser;
    if (user == null) return false;

    await _firestore.collection("Users").doc(user.email).set({
      'weight': weight,
      'goalWeight': weight,
    }, SetOptions(merge: true));

    // Update weight history
    final today = DateTime.now();
    await _firestore.collection('weight_history')
        .doc('${user.uid}_${DateFormat('yyyy-MM-dd').format(today)}')
        .set({
      'userId': user.uid,
      'weight': weight,
      'date': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update local data
    if (_userData != null) {
      _userData!['weight'] = weight;
      _userData!['goalWeight'] = weight;
    }
    notifyListeners();

    return true;
  } catch (e) {
    print("Error updating weight: $e");
    return false;
  }
}
}


