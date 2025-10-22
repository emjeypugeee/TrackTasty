import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/helper/helper_function.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Hidden gesture counter
  int _logoPressCount = 0;
  DateTime? _lastLogoPressTime;

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

  // Handle logo tap for hidden admin access
  void _handleLogoPress() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds have passed
    if (_lastLogoPressTime == null ||
        now.difference(_lastLogoPressTime!) > const Duration(seconds: 2)) {
      _logoPressCount = 0;
    }

    _logoPressCount++;
    _lastLogoPressTime = now;

    if (_logoPressCount >= 5) {
      _logoPressCount = 0; // Reset counter
      _navigateToAdminLogin();
    }
  }

  void _navigateToAdminLogin() {
    context.push('/adminlogin');
  }

  // Check if user is admin and prevent login if they are
  Future<bool> _isAdminUser(String email) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(email.trim())
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final isAdmin = userData['isAdmin'] ?? false;
        final hasDailyCalories = userData['dailyCalories'] != null;

        // Admin users should not have dailyCalories field
        return isAdmin == true && !hasDailyCalories;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking admin status: $e");
      return false;
    }
  }

  // log in method
  void login() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if user is trying to login as admin
    final email = emailController.text.trim();
    if (await _isAdminUser(email)) {
      if (context.mounted) {
        displayMessageToUser(
            "Invalid credentials. Try to login with an existing account.",
            context);
      }
      return;
    }

    // Show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // try sign in
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user?.email)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Additional check to ensure admin cannot login here
        final isAdmin = userData['isAdmin'] ?? false;
        final hasDailyCalories = userData['dailyCalories'] != null;

        if (isAdmin == true && !hasDailyCalories) {
          // Admin trying to login through normal page - sign them out
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pop(context);
            displayMessageToUser(
                "Invalid credentials. Try to login with an existing account.",
                context);
          }
          return;
        }

        // Pop loading circle and navigate to home page for non-admin users
        if (context.mounted) {
          Navigator.pop(context);
          context.push('/home');
        }
      } else {
        // Handle case where user data is not found, default to home page
        if (context.mounted) {
          Navigator.pop(context);
          context.push('/home');
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
                  // logo with hidden gesture
                  GestureDetector(
                    onTap: _handleLogoPress,
                    child: Image.asset('lib/images/TrackTastyLogo.png'),
                  ),

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
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(80),
                    ],
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
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(64),
                    ],
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
