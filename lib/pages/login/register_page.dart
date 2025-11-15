import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/model/user_data_models.dart';
import 'package:fitness/utils/goal_achievement_utils.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/bottom_sheet_widgets/terms_conditions_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _agreeToTerms = false;
  Timer? _otpExpiryTimer;
  Timer? _resendCooldownTimer;
  int _remainingSeconds = 0;
  String? _generatedOTP;
  DateTime? _otpExpiryTime;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  // EmailJS Configuration - Replace with your actual credentials
  static const String _emailJSServiceID = 'service_wyk93ov';
  static const String _emailJSTemplateID = 'template_ufj8t6e';
  static const String _emailJSPublicKey = 'CeaO7hVFAPoSU6sRw';
  static const String _emailJSPrivateKey = 'NQ-S89CddcgVIO1aNv7BR';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetAllState();
    _loadUserData();
    _initializeEmailJS();
  }

  Future<void> _initializeEmailJS() async {
    try {
      // Initialize EmailJS with your credentials
      emailjs.init(
        emailjs.Options(
          publicKey: _emailJSPublicKey,
          privateKey: _emailJSPrivateKey,
          limitRate: emailjs.LimitRate(
            // Set the limit rate for the application
            id: 'app',
            // Allow 1 request per 10s
            throttle: 10000,
          ),
        ),
      );
      debugPrint('(REGISTER PAGE) EmailJS initialized successfully');
    } catch (error) {
      debugPrint('(REGISTER PAGE) Failed to initialize EmailJS: $error');
    }
  }

  void _loadUserData() {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    provider.loadFromPreferences();
    final userData = provider.userData;

    debugPrint("Loaded User Data: ${userData.toMap()}");
  }

  void _resetAllState() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _otpController.clear();

    _isLoading = false;
    _otpSent = false;
    _otpVerified = false;
    _agreeToTerms = false;
    _generatedOTP = null;
    _otpExpiryTime = null;
    _remainingSeconds = 0;

    _otpExpiryTimer?.cancel();
    _resendCooldownTimer?.cancel();
    _otpExpiryTimer = null;
    _resendCooldownTimer = null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _otpFocusNode.dispose();
    _otpExpiryTimer?.cancel();
    _resendCooldownTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // OTP Generation and Management
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit OTP
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showError('Please agree to the Terms and Conditions to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      // Check if user already exists with completed registration
      final userDoc =
          await FirebaseFirestore.instance.collection("Users").doc(email).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final hasDailyCalories = userData?['dailyCalories'] != null;

        if (hasDailyCalories) {
          setState(() => _isLoading = false);
          _showError(
              'An account with this email already exists. Please sign in instead.');
          return;
        }
      }

      // Generate and store OTP
      _generatedOTP = _generateOTP();
      _otpExpiryTime =
          DateTime.now().add(Duration(minutes: 10)); // 10-minute expiry

      // Store OTP in Firestore
      await FirebaseFirestore.instance
          .collection('otpVerifications')
          .doc(email)
          .set({
        'otp': _generatedOTP,
        'expiresAt': Timestamp.fromDate(_otpExpiryTime!),
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'attempts': 0,
      });

      // Send OTP via EmailJS
      await _sendOTPEmail(email, _generatedOTP!);

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });

      _startOTPExpiryTimer();
      _startResendCooldown();

      _showSuccess('OTP sent to your email address. It expires in 10 minutes.');
    } catch (e) {
      _showError('Error sending OTP: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOTPEmail(String email, String otp) async {
    try {
      // EmailJS template parameters
      final templateParams = {
        'to_email': email,
        'otp_code': otp,
        'expiry_minutes': '10',
        'app_name': 'TrackTasty',
        'current_year': DateTime.now().year.toString(),
      };

      // Send email using EmailJS
      await emailjs.send(
        _emailJSServiceID,
        _emailJSTemplateID,
        templateParams,
        const emailjs.Options(
          publicKey: _emailJSPublicKey,
          privateKey: _emailJSPrivateKey,
        ),
      );

      debugPrint('OTP email sent successfully to $email');
    } catch (error) {
      debugPrint('Failed to send OTP email: $error');
      // If email fails, show OTP in dialog as fallback
      _showOTPDialog(otp);
      throw Exception('Failed to send email: $error');
    }
  }

  void _showOTPDialog(String otp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.containerBg,
        title: Text(
          'OTP Verification',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Email service temporarily unavailable. Here is your OTP:',
              style: TextStyle(color: AppColors.primaryText),
            ),
            SizedBox(height: 16),
            Text(
              otp,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This OTP expires in 10 minutes.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      _showError('Please enter the OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final enteredOTP = _otpController.text.trim();

      // Get OTP document from Firestore
      final otpDoc = await FirebaseFirestore.instance
          .collection('otpVerifications')
          .doc(email)
          .get();

      if (!otpDoc.exists) {
        _showError('OTP not found. Please request a new OTP.');
        setState(() => _isLoading = false);
        return;
      }

      final otpData = otpDoc.data()!;
      final storedOTP = otpData['otp'] as String;
      final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();
      final attempts = otpData['attempts'] as int;

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiresAt)) {
        await otpDoc.reference.delete();
        _showError('OTP has expired. Please request a new one.');
        setState(() => _isLoading = false);
        return;
      }

      // Check attempt limit
      if (attempts >= 5) {
        await otpDoc.reference.delete();
        _showError('Too many failed attempts. Please request a new OTP.');
        setState(() => _isLoading = false);
        return;
      }

      // Verify OTP
      if (enteredOTP == storedOTP) {
        // OTP verified successfully
        await otpDoc.reference.delete();

        setState(() {
          _otpVerified = true;
          _isLoading = false;
        });

        _otpExpiryTimer?.cancel();
        _showSuccess('Email verified successfully!');
      } else {
        // Increment failed attempts
        await otpDoc.reference.update({
          'attempts': FieldValue.increment(1),
        });

        final remainingAttempts = 5 - (attempts + 1);
        _showError('Invalid OTP. $remainingAttempts attempts remaining.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error verifying OTP: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startOTPExpiryTimer() {
    _otpExpiryTimer?.cancel();
    _otpExpiryTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_otpExpiryTime == null) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final difference = _otpExpiryTime!.difference(now);

      if (difference.isNegative) {
        setState(() {
          _remainingSeconds = 0;
          _otpSent = false;
        });
        timer.cancel();
        _showError('OTP has expired. Please request a new one.');
      } else {
        setState(() {
          _remainingSeconds = difference.inSeconds;
        });
      }
    });
  }

  void _startResendCooldown() {
    setState(() => _remainingSeconds = 60); // 1 minute cooldown

    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _registerUser() async {
    if (!_otpVerified) {
      _showError('Please verify your email with OTP before proceeding.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Create user account in Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await _createUserDocument(userCredential.user!);
      await _saveInitialWeight(userCredential.user!.uid);
      await _saveGoalWeight(userCredential.user!.uid);

      // Clear any temporary data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pendingVerificationEmail');

      if (!mounted) return;

      final provider =
          Provider.of<RegistrationDataProvider>(context, listen: false);
      provider.reset();

      _resetAllState();

      context.go('/home');
      _showSuccess('Account created successfully!');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError(
            'An account with this email already exists. Please sign in instead.');
      } else {
        _showError('Registration failed: ${e.message}');
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Registration failed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDocument(User user) async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    provider.loadFromPreferences();
    final userData = provider.userData;

    await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
      'email': user.email,
      'userId': user.uid,
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
      'emailVerified': true,
    });
  }

  // In register_page.dart, update the _saveGoalWeight method:

  Future<void> _saveGoalWeight(String userId) async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    final userData = provider.userData;

    try {
      // Ensure we have non-null values with defaults
      final goalWeight = userData.goalWeight ?? 0.0;
      final currentWeight = userData.weight ?? 0.0;
      final goalType = userData.goal ?? 'Maintain Weight';
      final measurementSystem = userData.measurementSystem ?? 'Metric';

      // Save the goal using GoalAchievementUtils
      await GoalAchievementUtils.saveUserGoal(
        userId: userId,
        userEmail: _emailController.text.trim(),
        goalType: goalType,
        goalWeight: goalWeight,
        currentWeight: currentWeight,
        measurementSystem: measurementSystem,
      );

      debugPrint('✅ Goal weight saved successfully: $goalWeight');
    } catch (e) {
      debugPrint('❌ Error saving goal weight: $e');
      // Don't throw here as this shouldn't block registration
    }
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
    debugPrint(message);
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
          onChanged: _otpSent
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
          absorbing: _otpSent,
          child: GestureDetector(
            onTap: _otpSent
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

  Widget _buildOTPField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verification Code',
            style: TextStyle(color: AppColors.primaryText)),
        const SizedBox(height: 5),
        MyTextfield(
          controller: _otpController,
          focusNode: _otpFocusNode,
          hintText: "Enter 6-digit OTP",
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            _otpFocusNode.unfocus();
          },
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Enter OTP';
            if (value!.length != 6) return 'OTP must be 6 digits';
            return null;
          },
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
          ],
          obscureText: false,
        ),
        if (_remainingSeconds > 0 && _otpSent && !_otpVerified) ...[
          const SizedBox(height: 8),
          Text(
            'OTP expires in: ${_formatTime(_remainingSeconds)}',
            style: TextStyle(
              color: _remainingSeconds < 60 ? Colors.orange : Colors.green,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  void _showExitConfirmation() {
    final router = GoRouter.of(context);

    if (_otpSent && !_otpVerified) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.containerBg,
          title: const Text(
            'Leave Registration?',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: const Text(
            'Your email verification is in progress. If you leave now, you\'ll need to start over.',
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
              onPressed: () {
                Navigator.of(context).pop();
                _resetAllState();
                router.go('/preference7');
              },
              child: const Text('Leave',
                  style: TextStyle(color: AppColors.primaryColor)),
            ),
          ],
        ),
      );
    } else {
      _resetAllState();
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
                            if (_otpSent && !_otpVerified) ...[
                              const SizedBox(height: 20),
                              _buildOTPField(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_otpSent)
                        MyButtons(
                          text: "Send Verification OTP",
                          onTap: _sendOTP,
                        ),
                      if (_otpSent && !_otpVerified) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "A 6-digit OTP has been sent to your email address.",
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Please check your inbox and enter the code above.",
                                style: TextStyle(
                                  color: Colors.orange[300],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        MyButtons(
                          text: "Verify OTP",
                          onTap: _verifyOTP,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _remainingSeconds > 0 ? null : _sendOTP,
                          child: Text(
                            _remainingSeconds > 0
                                ? 'Resend OTP (${_formatTime(_remainingSeconds)})'
                                : 'Resend OTP',
                            style: TextStyle(
                              color: _remainingSeconds > 0
                                  ? Colors.grey
                                  : AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                      if (_otpVerified) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Email verified successfully!",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
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
          enabled: !_otpSent,
          inputFormatters: [
            LengthLimitingTextInputFormatter(80),
          ],
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
          hintText: "Enter your password (8+ characters)",
          textInputAction: TextInputAction.next,
          enabled: !_otpSent,
          inputFormatters: [
            LengthLimitingTextInputFormatter(64),
          ],
          onFieldSubmitted: (_) {
            _confirmPasswordFocusNode.requestFocus();
          },
          obscureText: true,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Enter your password';
            if (value!.length < 8) {
              return 'Password must be at least 8 characters';
            }
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
          enabled: !_otpSent,
          inputFormatters: [
            LengthLimitingTextInputFormatter(64),
          ],
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
