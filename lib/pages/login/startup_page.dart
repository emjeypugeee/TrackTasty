import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/square_tile.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class StartupPage extends StatelessWidget {
// onTap method to register page

  StartupPage({
    super.key,
  });

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
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //google button
                  SizedBox(
                    width: 25,
                  ),

                  //apple button
                  SquareTile(imagePath: 'lib/images/google.png'),

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
