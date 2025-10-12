import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/square_tile.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/bottom_sheet_widgets/faq_widget.dart';
import 'package:fitness/widgets/main_screen_widgets/bottom_sheet_widgets/terms_conditions_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
  }

  var duration = const Duration(seconds: 5);

  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.containerBg,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => const FAQWidget(),
    );
  }

  void _showTermsAndCondition(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.containerBg,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => const TermsConditionsWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginPagesBg,
      body: Column(
        children: [
          // Expanded takes all available space and centers the main content
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //logo
                    Image.asset('lib/images/TrackTastyLogo.png'),

                    //Sign Up button
                    MyButtons(
                      text: 'Sign-up',
                      onTap: () {
                        context.go('/preference1');
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
                  ],
                ),
              ),
            ),
          ),

          // FAQ and T&C section at the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Column(
              children: [
                // Horizontal line separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Divider(
                    color: AppColors.titleText.withValues(alpha: 0.3),
                    thickness: 1,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 20),

                // FAQ and T&C buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // FAQ Button
                    TextButton(
                      onPressed: () => _showFAQ(context),
                      child: const Text(
                        'FAQs',
                        style: TextStyle(
                          color: AppColors.titleText,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    // Terms & Conditions Button
                    TextButton(
                      onPressed: () => _showTermsAndCondition(context),
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: AppColors.titleText,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
