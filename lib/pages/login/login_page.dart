// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/my_textfield.dart';
import 'package:fitness/helper/helper_function.dart';
import 'package:flutter/material.dart';

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

  //to track state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
          Navigator.pushNamed(context, '/Userpreference1Page');
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

  // navigate to forget password page
  void goToForgetpasswordPage(BuildContext context) {
    Navigator.pushNamed(context, '/ForgetpasswordPage');
  }

// -------------------
// UI build
// -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF121212),
      //back button
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        leading: BackButton(
          color: const Color(0xFFE99797),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),

          //form
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logo
                const Icon(
                  Icons.person,
                  size: 80,
                  color: Color(0xFFE99797),
                ),

                const SizedBox(height: 25),

                // name
                const Text(
                  'T R A C K T A S T Y',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFFE99797)),
                ),

                const SizedBox(height: 25),

                //Email Address text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email Address',
                    style: TextStyle(color: Color(0xFFFFFFFF)),
                  ),
                ),

                const SizedBox(height: 5),

                // username tb
                MyTextfield(
                  hintText: "Value",
                  obscureText: false,
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a email';
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
                    style: TextStyle(color: Color(0xFFFFFFFF)),
                  ),
                ),

                // password tb
                MyTextfield(
                  hintText: "Value",
                  obscureText: true,
                  controller: passwordController,
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
                    goToForgetpasswordPage(context);
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFFE99797)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
