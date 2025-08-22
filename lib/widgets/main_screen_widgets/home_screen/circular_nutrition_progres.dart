import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CircularNutritionProgres extends StatefulWidget {
  final String macroType;
  final Color progressColor;
  final String value;
  final String label;
  final DateTime selectedDate;

  const CircularNutritionProgres({
    super.key,
    required this.macroType,
    required this.progressColor,
    required this.value,
    required this.label,
    required this.selectedDate,
  });

  @override
  State<CircularNutritionProgres> createState() =>
      _CircularNutritionProgresState();
}

class _CircularNutritionProgresState extends State<CircularNutritionProgres>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0.0;
  double progress = 0.0;
  double overflowProgress = 0.0;
  double totalMacro = 0.0;
  double consumedMacro = 0.0;
  StreamSubscription<DocumentSnapshot>? _foodLogSubscription;
  String? _currentFoodLogDocId;
  // bool _initialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load user macro goals once
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      _updateTotalMacro(data);
    }

    // Set up food log subscription for current date
    _setupFoodLogSubscription(user);
    //  _initialDataLoaded = true;
  }

  void _setupFoodLogSubscription(User user) {
    final date = widget.selectedDate;
    final newDocId = '${user.uid}_${date.year}-${date.month}-${date.day}';

    // Only update if the document ID has changed
    if (_currentFoodLogDocId == newDocId) return;

    // Cancel previous subscription
    _foodLogSubscription?.cancel();
    _currentFoodLogDocId = newDocId;

    _foodLogSubscription = FirebaseFirestore.instance
        .collection('food_logs')
        .doc(newDocId)
        .snapshots()
        .listen((doc) {
      if (mounted) {
        setState(() {
          consumedMacro =
              (doc.data()?['total${widget.macroType}'] as num?)?.toDouble() ??
                  0.0;
          _updateProgress();
        });
      }
    });
  }

  void _updateTotalMacro(Map<String, dynamic> data) {
    dynamic value;
    switch (widget.macroType) {
      case 'Calories':
        value = data['dailyCalories'] ?? 2000.0;
        break;
      case 'Carbs':
        value = data['carbsGram'] ?? 250.0;
        break;
      case 'Protein':
        value = data['proteinGram'] ?? 100.0;
        break;
      case 'Fat':
        value = data['fatGram'] ?? 70.0;
        break;
      default:
        value = 0.0;
    }

    totalMacro = (value is int) ? value.toDouble() : value;
  }

  void _updateProgress() {
    _oldProgress = progress;
    progress = (consumedMacro / totalMacro).clamp(0.0, 1.0);
    overflowProgress = consumedMacro > totalMacro
        ? ((consumedMacro - totalMacro) / totalMacro).clamp(0.0, 1.0)
        : 0.0;

    _animation = Tween<double>(begin: _oldProgress, end: progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller
      ..reset()
      ..forward();
  }

  @override
  void didUpdateWidget(covariant CircularNutritionProgres oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if date or macro type changed
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.macroType != widget.macroType) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _setupFoodLogSubscription(user);
        if (widget.macroType != oldWidget.macroType) {
          // Reload macro goals if macro type changed
          _loadInitialData();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _foodLogSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*if (!_initialDataLoaded) {
      return const SizedBox(
        width: 120,
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }*/

    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.43,
      height: 120,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(25.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              width: 50,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _animation.value,
                        strokeWidth: 5,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation(widget.progressColor),
                      ),
                      if (overflowProgress > 0)
                        CircularProgressIndicator(
                          value: overflowProgress,
                          strokeWidth: 5,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(Colors.red),
                        ),
                      Center(
                        child: Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
