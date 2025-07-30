import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/square_tile.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    // Ensure the user is redirected to home page if already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Future.microtask(() => context.go('/home'));
    }
  }

  var duration = const Duration(seconds: 5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginPagesBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo
              Image.asset('lib/images/TrackTastyLogo.png'),

              //Sign Up buttton
              MyButtons(
                text: 'Sign-up',
                onTap: () {
                  context.go('/register');
                },
              ),

              const SizedBox(
                height: 25,
              ),

              //Already have an account text
              GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  context.go('/login');
                },
                child: const Text(
                  'I already have an account.',
                  style: TextStyle(color: AppColors.titleText),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              //spacing
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: AppColors.titleText),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              //google, facebook and apple login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //google button
                  GestureDetector(
                    onTap: () {
                      context.push('/home');
                    },
                    child: SquareTile(imagePath: 'lib/images/google.png'),
                  ),
                  SizedBox(width: 10),

                  SizedBox(
                    width: 10,
                  ),

                  //facebook button
                  SquareTile(imagePath: 'lib/images/apple.png'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
