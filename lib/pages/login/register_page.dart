import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/model/user_data_models.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness/provider/registration_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  bool _emailSent = false;
  bool _emailVerified = false;
  bool _agreeToTerms = false; // Added for terms agreement
  Timer? _emailCheckTimer;
  User? _temporaryUser;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _checkForExistingVerification();
  }

  void _loadSavedData() {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    // Check if there's any saved email in the provider
    if (provider.userData.email != null) {
      _emailController.text = provider.userData.email!;
    }
  }

  void _checkForExistingVerification() async {
    // Check if user was in the middle of verification process
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('pendingVerificationEmail');

    if (email != null) {
      // User was verifying this email, check if it's now verified
      try {
        // Try to sign in to check verification status
        final password = prefs.getString('pendingVerificationPassword');
        if (password != null) {
          final userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);

          if (userCredential.user != null) {
            await userCredential.user!.reload();
            if (userCredential.user!.emailVerified) {
              setState(() {
                _emailSent = true;
                _emailVerified = true;
                _temporaryUser = userCredential.user;
                _emailController.text = email;
              });
            } else {
              setState(() {
                _emailSent = true;
                _temporaryUser = userCredential.user;
                _emailController.text = email;
              });
              _startEmailVerificationCheck(userCredential.user!);
            }
          }
        }
      } catch (e) {
        // Couldn't sign in, clear the stored data
        await prefs.remove('pendingVerificationEmail');
        await prefs.remove('pendingVerificationPassword');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _emailCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if user agreed to terms
    if (!_agreeToTerms) {
      _showError('Please agree to the Terms and Conditions to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Store credentials for later retrieval
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'pendingVerificationEmail', _emailController.text.trim());
      await prefs.setString(
          'pendingVerificationPassword', _passwordController.text.trim());

      // Create a temporary user with email and password
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save email to provider by updating the userData
      final provider =
          Provider.of<RegistrationDataProvider>(context, listen: false);

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      setState(() {
        _emailSent = true;
        _isLoading = false;
        _temporaryUser = userCredential.user;
      });

      _showSuccess('Verification email sent. Please check your inbox.');

      // Start checking for email verification status
      _startEmailVerificationCheck(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Try to sign in and check if email is verified
        await _handleExistingUser();
      } else {
        _showError('Error sending verification email: ${e.message}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleExistingUser() async {
    try {
      // Try to sign in with the provided credentials
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Store credentials for later retrieval
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'pendingVerificationEmail', _emailController.text.trim());
      await prefs.setString(
          'pendingVerificationPassword', _passwordController.text.trim());

      // Check if email is already verified
      await userCredential.user!.reload();
      if (userCredential.user!.emailVerified) {
        setState(() {
          _emailSent = true;
          _emailVerified = true;
          _isLoading = false;
          _temporaryUser = userCredential.user;
        });
        _showSuccess(
            'Email already verified. You can now complete registration.');
      } else {
        // Resend verification email
        await userCredential.user!.sendEmailVerification();

        setState(() {
          _emailSent = true;
          _isLoading = false;
          _temporaryUser = userCredential.user;
        });

        _showSuccess('Verification email resent. Please check your inbox.');
        _startEmailVerificationCheck(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      _showError('Error: ${e.message}');
      setState(() => _isLoading = false);
    }
  }

  void _startEmailVerificationCheck(User user) {
    _emailCheckTimer?.cancel();
    _emailCheckTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        if (updatedUser != null && updatedUser.emailVerified) {
          timer.cancel();
          setState(() {
            _emailVerified = true;
          });
          _showSuccess('Email verified! You can now complete registration.');
        }
      } catch (e) {
        // Error reloading user, stop the timer
        timer.cancel();
      }
    });
  }

  Future<void> _registerUser() async {
    if (!_emailVerified || _temporaryUser == null) {
      _showError('Please verify your email before proceeding.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Ensure email is still verified
      await _temporaryUser!.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser == null || !updatedUser.emailVerified) {
        _showError('Email not verified. Please verify your email first.');
        setState(() => _isLoading = false);
        return;
      }

      // Save user data to Firestore
      await _createUserDocument(updatedUser);

      // Save initial weight to weight_history
      await _saveInitialWeight(updatedUser.uid);

      // Clear stored verification data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pendingVerificationEmail');
      await prefs.remove('pendingVerificationPassword');

      if (!mounted) return;

      // Clear registration data from provider
      final provider =
          Provider.of<RegistrationDataProvider>(context, listen: false);
      provider.reset();

      context.go('/home');
      _showSuccess('Account created successfully!');
    } on FirebaseException catch (e) {
      _showError('Registration failed: ${e.message}');
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Registration failed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDocument(User user) async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    final userData = provider.userData;

    await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
      'email': user.email,
      'username': userData.username,
      'age': userData.age,
      'gender': userData.gender,
      'activityLevel': userData.activityLevel,
      'goal': userData.goal,
      'height': userData.height,
      'weight': userData.weight,
      'goalWeight': userData.goalWeight,
      'measurementSystem': userData.measurementSystem,
      'dietaryPreference': userData.dietaryPreference,
      'allergies': userData.allergies,
      'dailyCalories': userData.dailyCalories,
      'carbsPercentage': userData.carbsPercentage,
      'fatsPercentage': userData.fatsPercentage,
      'proteinPercentage': userData.proteinPercentage,
      'carbsGram': userData.carbsGram,
      'fatsGram': userData.fatsGram,
      'proteinGram': userData.proteinGram,
      'dateAccountCreated': DateTime.now(),
      'isAdmin': false,
      'lastPreferenceStep': 7,
      'preferencesCompleted': true,
      'profileImage': null,
      'agreedToTerms': true, // Record that user agreed to terms
      'termsAgreementDate': DateTime.now(), // Record when they agreed
    });
  }

  Future<void> _saveInitialWeight(String userId) async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    final currentDate = DateTime.now();

    await FirebaseFirestore.instance.collection("weight_history").doc().set({
      'userId': userId,
      'date': Timestamp.fromDate(currentDate),
      'weight': provider.userData.weight,
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Your provided function
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              // Drag handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Divider(
                color: AppColors.primaryText.withOpacity(0.3),
                thickness: 1,
              ),
              const SizedBox(height: 20),

              // 1. Acceptance of Terms
              Text(
                '1. ACCEPTANCE OF TERMS',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By accessing or using TrackTasty ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to all terms, please discontinue use immediately. Continued use constitutes acceptance of any modifications.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 2. Service Description
              Text(
                '2. SERVICE DESCRIPTION',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TrackTasty is a macro-nutrient tracking application designed to help beginners monitor food intake, calculate nutritional requirements, and support weight management goals. The App provides personalized macro calculations based on user-provided information including age, gender assigned at birth, weight, height, activity level, weight goals, dietary preferences, and allergies.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 3. User GUIDELINES
              Text(
                '3. USER GUIDELINES',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• You must provide accurate and complete information for macro calculations\n• You agree to use the App only for lawful purposes\n• You must be at least 14 years old to use the App\n• You acknowledge that results may vary based on individual adherence',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 4. Medical Disclaimer
              Text(
                '4. MEDICAL DISCLAIMER',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TrackTasty provides nutritional information and tracking tools for informational purposes only. The App is not intended to diagnose, treat, cure, or prevent any disease or health condition. Always consult with a qualified healthcare professional before making significant changes to your diet or exercise routine. The macro calculations are estimates and should be used as guidelines rather than strict prescriptions.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 5. Data Collection and Privacy
              Text(
                '5. DATA COLLECTION AND PRIVACY',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We collect personal information (such as your preferences and app usage) to provide and improve our services. Your data is stored securely and handled according to our Privacy Policy. By using TrackTasty, you agree to the collection and processing of your data as described in our Privacy Policy. We comply with the Data Privacy Act of 2012 (Republic Act No. 10173) and ensure that your personal information is collected, used, and protected in accordance with Philippine data privacy laws.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 6. Intellectual Property
              Text(
                '6. INTELLECTUAL PROPERTY',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All content, features, and functionality developed by us for the TrackTasty application are owned by us and are protected by international copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, or create derivative works of our proprietary content without our explicit permission.\n\nHowever, the application utilizes data and services provided by third-party APIs, including but not limited to Gemini API (Google), FatSecret Platform (FatSecret), and DeepSeek API (DeepSeek). The use of any content, data, or functionality provided by these third-party APIs is governed by their respective terms of service and intellectual property policies. You acknowledge and agree that we are not the owners of this third-party content and are not responsible for your use of it.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 7. Limitation of Liability
              Text(
                '7. LIMITATION OF LIABILITY',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TrackTasty and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the App. This includes but is not limited to errors in macro calculations, nutritional information, or any health-related outcomes.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 8. Modifications to Terms
              Text(
                '8. MODIFICATIONS TO TERMS',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We reserve the right to modify these Terms and Conditions at any time. Continued use of the App after changes constitutes acceptance of the modified terms. Users will be notified of significant changes through the App or via email.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 9. Termination
              Text(
                '9. TERMINATION',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We may terminate or suspend your access to TrackTasty immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users or the App\'s operation.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Acceptance Note
              Center(
                child: Text(
                  'By using TrackTasty, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for terms and conditions checkbox
  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: _emailSent
              ? null
              : (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
          activeColor: AppColors.primaryColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        AbsorbPointer(
          absorbing: _emailSent,
          child: Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _agreeToTerms = !_agreeToTerms;
                });
              },
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _showTermsAndCondition(context);
                        },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginPagesBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.backButton),
          onPressed: () => context.go('/preference7'),
        ),
        backgroundColor: AppColors.loginPagesBg,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(25.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('lib/images/TrackTastyLogo.png', height: 200),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildEmailField(),
                          const SizedBox(height: 20),
                          _buildPasswordField(),
                          const SizedBox(height: 20),
                          _buildConfirmPasswordField(),
                          const SizedBox(height: 20),
                          _buildTermsCheckbox(), // Added terms checkbox
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_emailSent)
                      MyButtons(
                        text: "Send Verification Email",
                        onTap: _sendVerificationEmail,
                      ),
                    if (_emailSent && !_emailVerified) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "A verification email has been sent to your email address. Please verify your email to continue.",
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      MyButtons(
                        text: "Resend Verification Email",
                        onTap: _sendVerificationEmail,
                      ),
                    ],
                    if (_emailVerified) ...[
                      const SizedBox(height: 20),
                      MyButtons(
                        text: "Create Account",
                        onTap: _registerUser,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Email Address',
            style: TextStyle(color: AppColors.primaryText)),
        const SizedBox(height: 5),
        MyTextfield(
          controller: _emailController,
          focusNode: _emailFocusNode,
          hintText: "Enter a valid email address",
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            _passwordFocusNode.requestFocus();
          },
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Enter your email';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
              return 'Enter a valid email address';
            }
            return null;
          },
          obscureText: false,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(color: AppColors.primaryText)),
        const SizedBox(height: 5),
        MyTextfield(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          showVisibilityIcon: true,
          hintText: "Enter your password (6+ characters)",
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            _confirmPasswordFocusNode.requestFocus();
          },
          obscureText: true,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Enter your password';
            if (value!.length < 6)
              return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirm Password',
            style: TextStyle(color: AppColors.primaryText)),
        const SizedBox(height: 5),
        MyTextfield(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          showVisibilityIcon: true,
          hintText: "Confirm Password",
          obscureText: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            _confirmPasswordFocusNode.unfocus();
          },
          validator: (value) => value != _passwordController.text
              ? 'Passwords do not match'
              : null,
        ),
      ],
    );
  }
}
