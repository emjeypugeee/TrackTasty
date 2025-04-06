import 'package:flutter/material.dart';

class CircularDayProgress extends StatelessWidget {
  final double progress;
  final String day;
  const CircularDayProgress(
      {super.key, required this.day, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: 52,
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation(Color(0xFFE99797)),
            ),
          )
        ],
      ),
    );
  }
}
