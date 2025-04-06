import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/square_tile.dart';
import 'package:flutter/material.dart';

class StartupPage extends StatelessWidget {
// onTap method to register page
  final void Function()? onTap;

  const StartupPage({
    super.key,
    required this.onTap,
  });

  // sign up method
  void signup() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //text
              const Text(
                'TrackTasty Logo',
                style: TextStyle(
                    fontSize: 50, color: Color(0xFFE99797), height: 3),
              ),

              //Sign Up buttton
              MyButtons(
                text: 'Sign-up',
                onTap: signup,
              ),

              const SizedBox(
                height: 25,
              ),

              //Already have an account text
              const Text(
                'I already have an account.',
                style: TextStyle(color: Color(0xFFE99797)),
              ),

              const SizedBox(
                height: 25,
              ),

              //spacing
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25.0),
                      child: Text(
                        'Or',
                        style: TextStyle(color: Color(0xFFE99797)),
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
              //google, facebook and apple login
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //google button
                  SquareTile(
                    imagePath: 'lib/images/facebook_logo.png',
                  ),

                  SizedBox(
                    width: 25,
                  ),

                  //apple button
                  SquareTile(imagePath: 'lib/images/google.png'),

                  SizedBox(
                    width: 25,
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
