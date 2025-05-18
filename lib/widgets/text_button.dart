import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String title;
  final double size;
  final void Function()? onTap;

  const CustomTextButton(
      {super.key,
      required this.title,
      required this.onTap,
      required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: TextStyle(color: AppColors.backButton, fontSize: size),
      ),
    );
  }
}
