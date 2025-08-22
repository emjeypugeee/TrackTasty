import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ForgetpasswordPage extends StatefulWidget {
  ForgetpasswordPage({super.key});

  @override
  State<ForgetpasswordPage> createState() => _ForgetpasswordPageState();
}

class _ForgetpasswordPageState extends State<ForgetpasswordPage> {
  bool _isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: () => context.pop(), // Use GoRouter's pop
        ),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Container(
            height: 350,
            width: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
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
                const SizedBox(height: 5),
                const Text(
                  'Enter the email you use to sign in to TrackTasty.',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Email Address',
                  style: TextStyle(fontSize: 16, color: AppColors.primaryText),
                ),
                const SizedBox(height: 5),
                MyTextfield(
                  hintText: 'Value',
                  obscureText: false,
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                MyButtons(
                  text: _isLoading ? 'Loading...' : 'Send',
                  onTap: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);
                            try {
                              await context
                                  .read<UserProvider>()
                                  .forgetPassword(emailController.text);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Password reset email sent!'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.snackBarBgSaved,
                                    duration:
                                        Duration(seconds: 3), // Add duration
                                  ),
                                );
                                context.push('/login');
                              }
                            } on FirebaseAuthException catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(e.code),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.snackBarBgError,
                                  duration:
                                      Duration(seconds: 3), // Add duration
                                ));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('Failed to send reset email.'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.snackBarBgError,
                                  duration:
                                      Duration(seconds: 3), // Add duration
                                ));
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
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
