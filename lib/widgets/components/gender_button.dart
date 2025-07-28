import 'package:flutter/material.dart';

class GenderIcon extends StatelessWidget {
  final bool isSelected;
  final IconData iconData;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const GenderIcon({
    super.key,
    required this.isSelected,
    required this.iconData,
    required this.onTap,
    this.selectedColor = Colors.black,
    this.unselectedColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20), // Perfect circle
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Icon(
          iconData,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}
