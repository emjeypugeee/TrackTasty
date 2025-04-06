// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/my_textfield.dart';
import 'package:fitness/helper/helper_function.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  // onTap toggle to login page

  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool checkedValue = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --------------------
  // text controller
  // --------------------
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cnfrmpasswordController = TextEditingController();

  // --------------------
  // register method
  // --------------------
  void registerUser() async {
    if (!checkedValue) {
      displayMessageToUser('Please agree to the terms & agreement', context);
      return null;
    } else {
      // loading circle
      showDialog(
          context: context,
          builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ));

      // make sure password match
      if (passwordController.text != cnfrmpasswordController.text) {
        // pop loading circle
        Navigator.pop(context);

        //show error message to user
        displayMessageToUser("Password don't match", context);
      } else if (passwordController.text == cnfrmpasswordController.text) {
        // pop loading circle
        Navigator.pop(context);

        //show successfull
        displayMessageToUser(
            "Your account has been successfully created", context);

        //navigate to login page
        Navigator.pushNamed(context, '/LoginPage');
      }

      try {
        // create user
        UserCredential? userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text.trim());

        //create a user document and add to firestore
        createUserDocument(userCredential);

        // pop loading circle
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        //pop loading circle
        Navigator.pop(context);

        //display error message
        displayMessageToUser(e.code, context);
      }
    }
  }

  // --------------------
  //create a user document and collect them in a flutter store
  // --------------------
  Future<void> createUserDocument(UserCredential? userCredential) async {
    if (userCredential != null && userCredential.user != null) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email)
          .set({
        'email': userCredential.user!.email,
      });
    }
  }

  // --------------------
  // UI Method
  // --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF121212),

      //back button
      appBar: AppBar(
        leading: BackButton(
            color: const Color(0xFFe99797),
            onPressed: () {
              Navigator.pop(context);
            }),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logo
                const Icon(
                  Icons.person,
                  color: Color(0xFFE99797),
                  size: 80,
                ),

                const SizedBox(height: 25),
                // name
                const Text(
                  'R E G I S T E R',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFFE99797)),
                ),

                const SizedBox(height: 25),

                // email address text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email Address',
                    style: TextStyle(color: Color(0xFFFFFFFF)),
                  ),
                ),

                const SizedBox(height: 5),

                // Email address tb
                MyTextfield(
                  hintText: "Value",
                  obscureText: false,
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // Password text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password',
                    style: TextStyle(color: Color(0xFFFFFFFF)),
                  ),
                ),

                const SizedBox(height: 5),

                //Password textfield
                MyTextfield(
                  hintText: "Value",
                  obscureText: true,
                  controller: passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Confirm Password',
                    style: TextStyle(color: Color(0xFFFFFFFF)),
                  ),
                ),

                const SizedBox(height: 5),

                //confirm password textfield
                MyTextfield(
                  hintText: "Value",
                  obscureText: true,
                  controller: cnfrmpasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                //checkbox
                Row(
                  children: [
                    Checkbox(
                      value: checkedValue,
                      onChanged: (newBool) {
                        setState(() {
                          checkedValue = newBool ?? false;
                        });
                      },
                    ),
                    Text(
                      "I agree to the terms & conditions",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // login button
                MyButtons(
                  text: "Register",
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      registerUser();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
