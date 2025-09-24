import 'dart:ui';

import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class ScanLinePainter extends CustomPainter {
  final double animationValue;

  ScanLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw scanning line that moves from top to bottom
    final lineY = size.height * animationValue;
    canvas.drawLine(
      Offset(0, lineY),
      Offset(size.width, lineY),
      paint,
    );

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final cornerLength = 20.0;

    // Top-left corner
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0),
        cornerPaint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height),
        Offset(0, size.height - cornerLength), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant ScanLinePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
