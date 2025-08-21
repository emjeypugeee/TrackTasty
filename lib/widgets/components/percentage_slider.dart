import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class PercentageSlider extends StatelessWidget {
  final double value;
  final String label;
  final Color activeColor;
  final Color labelColor;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final bool isLocked;
  final VoidCallback onLockToggle;

  const PercentageSlider({
    super.key,
    required this.value,
    required this.label,
    required this.activeColor,
    required this.labelColor,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.isLocked,
    required this.onLockToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label (${value.toStringAsFixed(0)}%)',
              style: TextStyle(
                color: labelColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: SfSliderTheme(
                data: SfSliderThemeData(
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  activeTrackColor: isLocked ? Colors.grey : activeColor,
                  thumbColor: isLocked ? Colors.grey : activeColor,
                  overlayColor: isLocked
                      ? Colors.transparent
                      : activeColor.withOpacity(0.1),
                  activeDividerColor: isLocked ? Colors.grey : activeColor,
                  inactiveDividerColor: Colors.grey.withOpacity(0.3),
                  activeTickColor: isLocked ? Colors.grey : activeColor,
                  inactiveTickColor: Colors.grey.withOpacity(0.3),
                  activeLabelStyle: TextStyle(
                    color: isLocked ? Colors.grey : labelColor,
                  ),
                  inactiveLabelStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
                child: SfSlider(
                  min: min,
                  max: max,
                  value: value,
                  interval: 5,
                  showTicks: true,
                  showLabels: true,
                  enableTooltip: true,
                  onChanged: isLocked
                      ? null
                      : (dynamic value) => onChanged?.call(value.toDouble()),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isLocked ? Icons.lock : Icons.lock_open,
                color: isLocked ? Colors.red : labelColor,
                size: 30,
              ),
              onPressed: onLockToggle,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 15,
            ),
          ],
        ),
      ],
    );
  }
}
