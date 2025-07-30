import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class ForgetpasswordPage extends StatelessWidget {
  ForgetpasswordPage({super.key});

  //email text controller
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: AppColors.loginPagesBg,
            appBar: AppBar(
              backgroundColor: AppColors.loginPagesBg,
              centerTitle: true,
              title: const Text(
                'Forget Password',
                style: TextStyle(
                    color: AppColors.titleText, fontWeight: FontWeight.bold),
              ),
              leading: BackButton(
                color: AppColors.backButton,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: Center(
              child: Container(
                height: 500,
                width: 300,
                decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Forgot your password?',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Text(
                      'Enter the email you use to sign in to TrackTasty.',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    const Text(
                      'Email Address',
                      style:
                          TextStyle(fontSize: 16, color: AppColors.primaryText),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    MyTextfield(
                        hintText: 'Value',
                        obscureText: false,
                        controller: emailController),
                    const SizedBox(
                      height: 25,
                    ),
                    MyButtons(text: 'Submit', onTap: () {})
                  ],
                ),
              ),
            )));
  }
}
