import 'package:flutter/material.dart';
import 'package:fitness/theme/app_color.dart';

class Selectableactivitybutton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final GestureTapCallback onTap;

  const Selectableactivitybutton({
    super.key,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.radioButtonColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.buttonColor : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            Text(title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                )),
            if (subtitle != null)
              Text(subtitle!,
                  style: TextStyle(color: Colors.white, fontSize: 10))
          ],
        )),
      ),
    );
  }
}
