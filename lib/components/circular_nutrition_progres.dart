import 'package:flutter/material.dart';

class CircularNutritionProgres extends StatelessWidget {
  final double progress;
  final String value;
  final String label;

  const CircularNutritionProgres(
      {super.key,
      required this.progress,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 120,
      decoration: BoxDecoration(
        color: Color(0xFF262626),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(Color(0xFFE99797)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
