import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> updateUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection("Users").doc(user.email).set(
      {'username': username},
      SetOptions(merge: true),
    );
  }

  Future<void> updateUserGoals({required String goal, required String goalWeight}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection("Users").doc(user.email).set(
      {'goal': goal, 'goalWeight': goalWeight},
      SetOptions(merge: true),
    );
  }

  Future<void> signOut() => _auth.signOut();
}
// In your widget:
// final _userRepository = UserRepository(FirebaseFirestore.instance);

// Then use it like:
// bool success = await _userRepository.updateUsername(user.email, usernameController.text);
