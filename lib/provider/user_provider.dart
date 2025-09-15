import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  // Initialize user data (di ko alam gamitin)
  Future<void> fetchUserData() async {
    _isLoading = true;

    try {
      _user = _auth.currentUser;
      if (_user != null) {
        final doc =
            await _firestore.collection("Users").doc(_user?.email).get();
        _userData = doc.data();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Update UI
    }
  }

  // Update nickname
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
      return true; // Success
    } catch (e) {
      return false; // Failure
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      // Re-throw to handle in UI
      rethrow;
    } catch (e) {
      // Handle unexpected errors
      throw Exception("Failed to send reset email: $e");
    }
  }

  // Update preferences
  Future<bool> saveUserPreferences(String newGoalWeight, String newGoal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
        'goalWeight': newGoalWeight,
        'goal': newGoal,
      }, SetOptions(merge: true));
      _isLoading = false;
      notifyListeners();
      return true; // Success
    }
    return false; // Failed
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _userData = null;
    notifyListeners(); // Reset UI to login screen
  }
}
