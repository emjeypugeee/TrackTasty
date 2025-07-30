import 'package:flutter/material.dart';

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
          color: isSelected ? Color(0xFF352C4D) : Color(0xFF65558F),
          borderRadius: BorderRadius.circular(50),
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
