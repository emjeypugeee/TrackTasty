import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final String? suffixText;
  final String? Function(String?)? validator;

  const MyTextfield({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.suffixText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: TextStyle(color: Colors.white),
      controller: controller,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
            borderRadius: BorderRadius.circular(12)),
        hintText: hintText,
        suffixText: suffixText,
        hintStyle: const TextStyle(color: AppColors.secondaryText),
        errorStyle: TextStyle(color: Colors.red),
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }
}
