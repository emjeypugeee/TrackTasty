import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/theme/app_color.dart';

class StartupLogoPage extends StatefulWidget {
  const StartupLogoPage({super.key});

  @override
  State<StartupLogoPage> createState() => _StartupLogoPageState();
}

class _StartupLogoPageState extends State<StartupLogoPage> {
  @override
  void initState() {
    super.initState();
    // Run the redirection logic after the widget is built.
    // Future.microtask ensures this runs after the current frame is rendered.
    Future.delayed(const Duration(seconds: 1), () {
      _checkUserVerificationAndRedirectPage();
    });
  }

  Future<void> _checkUserVerificationAndRedirectPage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint("(STARTUP LOGO) User is logged in. UID: ${user.uid}");
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser?.email)
            .get();

        if (userDoc.exists) {
          debugPrint("(STARTUP LOGO) User document exists.");
          final userData = userDoc.data() as Map<String, dynamic>?;
          final dailyCalories = userData?['dailyCalories'];

          if (dailyCalories != null) {
            debugPrint(
                "(STARTUP LOGO) 'dailyCalories' field found. User is verified.");
            GoRouter.of(context).go('/home');
          } else {
            debugPrint(
                "(STARTUP LOGO) 'dailyCalories' field not found. Redirecting to startup.");
            GoRouter.of(context).go('/startup');
          }
        } else {
          debugPrint(
              "(STARTUP LOGO) User document does not exist. Redirecting to startup.");
          GoRouter.of(context).go('/startup');
        }
      } catch (e) {
        debugPrint("(STARTUP LOGO) Error checking user data: $e");
        GoRouter.of(context).go('/startup');
      }
    } else {
      debugPrint("(STARTUP LOGO) User not logged in. Redirecting to startup.");
      GoRouter.of(context).go('/startup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginPagesBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo
            Image.asset('lib/images/TrackTastyLogo.png'),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
