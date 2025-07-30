import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FadeOutPageTransition extends CustomTransitionPage<void> {
  FadeOutPageTransition({
    required super.key,
    required super.child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: curve,
                ),
              ),
              child: child,
            );
          },
        );
}
