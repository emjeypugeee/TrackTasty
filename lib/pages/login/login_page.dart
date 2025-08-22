// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/helper/helper_function.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  //to track state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load saved email if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

  // log in method
  void login() async {
    //shows loading cricle
    showDialog(
        context: context,
        builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ));

    // try sign in
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());

      //pop loading circle
      if (context.mounted) {
        if (_formKey.currentState!.validate()) {
          Navigator.pop(context);
          sleep(Durations.medium4);
          context.push('/home');
        }
      }

      //display error
    } on FirebaseAuthException catch (e) {
      // pop loading screen
      Navigator.pop(context);

      displayMessageToUser(e.code, context);
    } catch (e) {
      Navigator.pop(context); // Close loading circle
      displayMessageToUser("An unexpected Error: $e", context);
    }
  }

// -------------------
// UI build
// -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginPagesBg,
      //back button
      appBar: AppBar(
        backgroundColor: AppColors.loginPagesBg,
        leading: BackButton(
          color: AppColors.backButton,
          onPressed: () {
            context.push('/startup');
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),

          //form
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // logo
                  Image.asset('lib/images/TrackTastyLogo.png'),

                  //Email Address text
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email Address',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // username tb
                  MyTextfield(
                    hintText: "Enter your email",
                    obscureText: false,
                    controller: emailController,
                    focusNode: _emailFocusNode,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: (_) {
                      _passwordFocusNode.requestFocus();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  //Password Text
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),

                  // password tb
                  MyTextfield(
                    hintText: "Enter your password",
                    obscureText: true,
                    showVisibilityIcon: true,
                    controller: passwordController,
                    focusNode: _passwordFocusNode,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (_formKey.currentState!.validate()) {
                        // Proceed with login if all fields are valid
                        login();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  // login button
                  MyButtons(
                      text: "Login",
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          // Proceed with login if all fields are valid
                          login();
                        }
                      }),

                  const SizedBox(height: 10),

                  //forgot password text
                  GestureDetector(
                    onTap: () {
                      context.push('/forgetpassword');
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.titleText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
