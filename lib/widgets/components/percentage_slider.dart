import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class PercentageSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final double interval;
  final Color activeColor;
  final String label;
  final Color labelColor;
  final ValueChanged<dynamic> onChanged;

  const PercentageSlider({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    this.interval = 5,
    required this.labelColor,
    required this.activeColor,
    required this.label,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SfSliderTheme(
      data: SfSliderThemeData(
        activeLabelStyle: TextStyle(
          color: labelColor,
        ),
        inactiveLabelStyle: TextStyle(
          color: labelColor,
        ),
      ),
      child: SfSlider(
        value: value,
        min: min,
        max: max,
        interval: interval,
        activeColor: activeColor,
        showTicks: true,
        showLabels: true,
        enableTooltip: true,
        minorTicksPerInterval: 1,
        tooltipTextFormatterCallback:
            (dynamic actualValue, String formattedText) {
          return '$label: ${actualValue.toStringAsFixed(0)}%';
        },
        onChanged: onChanged,
      ),
    );
  }
}
