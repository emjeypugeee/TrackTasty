import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

Future<String?> handleRedirect(GoRouterState state) async {
  final user = FirebaseAuth.instance.currentUser;
  final authPaths = ['/login', '/register', '/startup'];

  if (user == null) {
    return authPaths.contains(state.uri.path) ? null : '/startup';
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();

    final preferencesCompleted = doc.data()?['preferencesCompleted'] ?? false;

    if (!preferencesCompleted) return '/preference1';

    if (state.uri.path == '/startup') return '/home';

    return null;
  } catch (e) {
    print('Redirect error: $e');
    return '/startup';
  }
}