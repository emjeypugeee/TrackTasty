import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextfield extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? suffixText;
  final bool? enabled;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final bool showVisibilityIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  const MyTextfield(
      {super.key,
      required this.hintText,
      required this.obscureText,
      required this.controller,
      this.suffixText,
      this.validator,
      this.keyboardType,
      this.enabled,
      this.focusNode,
      this.initialValue,
      this.showVisibilityIcon = false,
      this.textInputAction,
      this.onFieldSubmitted,
      this.inputFormatters});

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  bool _showPassword = false;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: TextStyle(color: Colors.white),
      controller: widget.controller,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
            borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
            borderRadius: BorderRadius.circular(12)),
        errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12)),
        hintText: widget.hintText,
        suffixText: widget.suffixText,
        hintStyle: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 14,
            overflow: TextOverflow.ellipsis),
        errorStyle: TextStyle(
            color: Colors.red, overflow: TextOverflow.clip, fontSize: 10),

        // Visibility icon for password field
        suffixIcon: widget.showVisibilityIcon
            ? IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.secondaryText,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              )
            : null,
      ),
      obscureText: widget.obscureText && !_showPassword,
      keyboardType: widget.keyboardType ?? TextInputType.text,
      validator: widget.validator,
      enabled: widget.enabled ?? true,
      initialValue: widget.initialValue,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      onFieldSubmitted: widget.onFieldSubmitted,
      focusNode: widget.focusNode,
    );
  }
}
