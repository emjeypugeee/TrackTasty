import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/model/user_data_models.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/bottom_sheet_widgets/terms_conditions_widget.dart';
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

class _RegisterPageState extends State<RegisterPage>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _emailSent = false;
  bool _emailVerified = false;
  bool _agreeToTerms = false;
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
    WidgetsBinding.instance.addObserver(this);
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
      try {
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
    WidgetsBinding.instance.removeObserver(this);
    _cleanupUnverifiedAccount();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App is going to background or being terminated
      _cleanupUnverifiedAccount();
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showError('Please agree to the Terms and Conditions to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'pendingVerificationEmail', _emailController.text.trim());
      await prefs.setString(
          'pendingVerificationPassword', _passwordController.text.trim());

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final provider =
          Provider.of<RegistrationDataProvider>(context, listen: false);

      await userCredential.user!.sendEmailVerification();

      setState(() {
        _emailSent = true;
        _isLoading = false;
        _temporaryUser = userCredential.user;
      });

      _showSuccess('Verification email sent. Please check your inbox.');
      _startEmailVerificationCheck(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await _handleExistingUser();
      } else {
        await _cleanupUnverifiedAccount();
        _showError('Error sending verification email: ${e.message}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      await _cleanupUnverifiedAccount();
      _showError('Error: $e');
      setState(() => _isLoading = false);
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
      await _temporaryUser!.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser == null || !updatedUser.emailVerified) {
        _showError('Email not verified. Please verify your email first.');
        setState(() => _isLoading = false);
        return;
      }

      await _createUserDocument(updatedUser);
      await _saveInitialWeight(updatedUser.uid);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pendingVerificationEmail');
      await prefs.remove('pendingVerificationPassword');

      if (!mounted) return;

      final provider =
          Provider.of<RegistrationDataProvider>(context, listen: false);
      provider.reset();

      // Clear the temporary user reference after successful registration
      _temporaryUser = null;

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
      'agreedToTerms': true,
      'termsAgreementDate': DateTime.now(),
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

  // Terms and Condition Page
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
          child: GestureDetector(
            onTap: _emailSent
                ? null
                : () {
                    setState(() {
                      _agreeToTerms = !_agreeToTerms;
                    });
                  },
            child: Container(
              constraints: BoxConstraints(
                minHeight: 48,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
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
        ),
      ],
    );
  }

  Future<void> _cleanupUnverifiedAccount() async {
    // Only cleanup if we have a temporary user that hasn't been verified
    if (_temporaryUser != null && !_emailVerified) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedEmail = prefs.getString('pendingVerificationEmail');

        if (storedEmail == _temporaryUser!.email) {
          await _temporaryUser!.delete();

          await prefs.remove('pendingVerificationEmail');
          await prefs.remove('pendingVerificationPassword');

          debugPrint('Unverified account deleted: ${_temporaryUser!.email}');
        }
      } catch (e) {
        debugPrint('Error cleaning up unverified account: $e');
      } finally {
        _temporaryUser = null;
      }
    }
  }

  void _showExitConfirmation() {
    final router = GoRouter.of(context);

    if (_temporaryUser != null && !_emailVerified) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.containerBg,
          title: const Text(
            'Leave Registration?',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: const Text(
            'Your account is not yet verified. If you leave now, your unverified account will be deleted and you\'ll need to start over.',
            style: TextStyle(color: AppColors.primaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Stay',
                style: TextStyle(color: AppColors.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cleanupUnverifiedAccount();
                router.go('/preference7');
              },
              child: const Text('Leave',
                  style: TextStyle(color: AppColors.primaryColor)),
            ),
          ],
        ),
      );
    } else {
      router.go('/preference7');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: AppColors.loginPagesBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.backButton),
            onPressed: () => _showExitConfirmation(),
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
                            _buildTermsCheckbox(),
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
