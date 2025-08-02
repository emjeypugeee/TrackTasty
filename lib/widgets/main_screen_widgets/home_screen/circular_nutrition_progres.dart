import 'package:flutter/material.dart';

class CircularNutritionProgres extends StatefulWidget {
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
  State<CircularNutritionProgres> createState() =>
      _CircularNutritionProgresState();
}

class _CircularNutritionProgresState extends State<CircularNutritionProgres>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _oldProgress = widget.progress;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation =
        Tween<double>(begin: _oldProgress, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CircularNutritionProgres oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _oldProgress = oldWidget.progress;
      _animation =
          Tween<double>(begin: _oldProgress, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseProgress = widget.progress.clamp(0.0, 1.0);
    final overflowProgress =
        widget.progress > 1.0 ? (widget.progress - 1.0).clamp(0.0, 1.0) : 0.0;
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.43,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
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
                              widget.value,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30),
                            ),
                            Text(
                              widget.label,
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
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final animatedBase = _animation.value.clamp(0.0, 1.0);
                  final animatedOverflow = _animation.value > 1.0
                      ? (_animation.value - 1.0).clamp(0.0, 1.0)
                      : 0.0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: animatedBase,
                        strokeWidth: 5,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFFE99797)),
                      ),
                      if (animatedOverflow > 0)
                        CircularProgressIndicator(
                          value: animatedOverflow,
                          strokeWidth: 5,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(Colors.red),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
