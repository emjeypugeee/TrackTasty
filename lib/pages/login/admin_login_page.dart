import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/helper/helper_function.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({
    super.key,
  });

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

  // Check if user is valid admin
  Future<bool> _isValidAdmin(String email) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(email.trim())
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final isAdmin = userData['isAdmin'] ?? false;
        return isAdmin == true;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking admin status: $e");
      return false;
    }
  }

  // admin login method
  void adminLogin() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (!await _isValidAdmin(email)) {
        if (context.mounted) {
          Navigator.pop(context);
          displayMessageToUser("Invalid admin credentials", context);
        }
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user?.email)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final isAdmin = userData['isAdmin'] ?? false;
        final hasDailyCalories = userData['dailyCalories'] != null;

        if (isAdmin == true && !hasDailyCalories) {
          // Successful admin login
          if (context.mounted) {
            Navigator.pop(context);
            context.push('/adminonly');
          }
        } else {
          // Not a valid admin - sign out
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pop(context);
            displayMessageToUser("Invalid admin credentials", context);
          }
        }
      } else {
        // User document not found
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pop(context);
          displayMessageToUser("Admin account not found", context);
        }
      }
    } on FirebaseAuthException catch (e) {
      // Pop loading screen
      if (context.mounted) {
        Navigator.pop(context);
        displayMessageToUser(e.code, context);
      }
    } catch (e) {
      // Close loading circle
      if (context.mounted) {
        Navigator.pop(context);
        displayMessageToUser("An unexpected Error: $e", context);
      }
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
            context.push('/login');
          },
        ),
        title: const Text(
          'Admin Login',
          style: TextStyle(color: AppColors.primaryText),
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

                  const SizedBox(height: 20),

                  // Admin label
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'ADMIN ACCESS',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  //Email Address text
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Admin Email',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // email textfield
                  MyTextfield(
                    hintText: "Enter admin email",
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
                        return 'Please enter admin email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  //Password Text
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Admin Password',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),

                  // password textfield
                  MyTextfield(
                    hintText: "Enter admin password",
                    obscureText: true,
                    showVisibilityIcon: true,
                    controller: passwordController,
                    focusNode: _passwordFocusNode,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (_formKey.currentState!.validate()) {
                        adminLogin();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter admin password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  // login button
                  MyButtons(
                    text: "Admin Login",
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        adminLogin();
                      }
                    },
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
