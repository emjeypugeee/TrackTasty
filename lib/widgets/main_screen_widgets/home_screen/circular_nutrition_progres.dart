import 'package:flutter/material.dart';

class CircularNutritionProgres extends StatelessWidget {
  final double progress;
  final String value;
  final String label;
  final bool overGoal;

  const CircularNutritionProgres({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
    this.overGoal = false,
  });

  @override
  Widget build(BuildContext context) {
    // Base Progress
    final baseProgress = progress.clamp(0.0, 1.0);
    // Overflow progress
    final overflowProgress =
        progress > 1.0 ? (progress - 1.0).clamp(0.0, 1.0) : 0.0;
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.43,
      height: 120,
      decoration: BoxDecoration(
        color: Color(0xFF262626),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
                        child: Column(
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30),
                            ),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            )
                          ],
                        )),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 1.0, 10, .0),
            child: SizedBox(
              height: 50,
              width: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base progress (up to goal)
                  CircularProgressIndicator(
                    value: baseProgress,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE99797)),
                  ),
                  // Overflow progress (over goal, in red)
                  if (overflowProgress > 0)
                    CircularProgressIndicator(
                      value: overflowProgress,
                      strokeWidth: 5,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
