import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/pages/login/startup_page.dart';
import 'package:fitness/pages/preference/userpreference_1.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            //user logged in
            if (snapshot.hasData) {
              return const Userpreference1();
            } else {
              //user is not logged in
              return const StartupPage();
            }
          }),
    );
  }
}
