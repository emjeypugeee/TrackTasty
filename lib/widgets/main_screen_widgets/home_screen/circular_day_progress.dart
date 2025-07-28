import 'package:flutter/material.dart';

class CircularDayProgress extends StatelessWidget {
  final double progress;
  final String day;
  const CircularDayProgress(
      {super.key, required this.day, required this.progress});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 80,
      width: screenWidth * 0.125,
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 40,
            width: screenWidth * 0.1,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation(Color(0xFFE99797)),
            ),
          )
        ],
      ),
    );
  }
}
