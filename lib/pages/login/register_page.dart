import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  bool _checkedValue = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes for text fields
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_checkedValue) {
      _showError('Please agree to the terms & conditions');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords don't match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _createUserDocument(userCredential);

      if (!mounted) return;
      context.go('/preference1'); // Redirect to login after success
      _showSuccess('Account created successfully!');
    } on FirebaseAuthException catch (e) {
      _showError(e.code);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDocument(UserCredential userCredential) async {
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(userCredential.user!.email)
        .set({
      'email': userCredential.user!.email,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginPagesBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.backButton),
          onPressed: () => context.go('/startup'), // GoRouter back navigation
        ),
        backgroundColor: AppColors.loginPagesBg,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset('lib/images/TrackTastyLogo.png', height: 280),
                      const SizedBox(height: 20),
                      _buildEmailField(),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 20),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 20),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 25),
                      MyButtons(
                        text: "Register",
                        onTap: _registerUser,
                      ),
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
          validator: (value) =>
              value?.isEmpty ?? true ? 'Enter your email' : null,
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
          validator: (value) =>
              value?.isEmpty ?? true ? 'Enter your password' : null,
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
          validator: (value) =>
              value != _passwordController.text ? 'Passwords mismatch' : null,
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _checkedValue,
          onChanged: (value) => setState(() => _checkedValue = value ?? false),
        ),
        const Text("I agree to the terms & conditions",
            style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
