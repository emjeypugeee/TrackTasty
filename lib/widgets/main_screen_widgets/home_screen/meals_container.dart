import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class MealsContainer extends StatefulWidget {
  final String mealName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String servingSize;
  final String adjustmentType;
  final double adjustmentValue;
  final DateTime loggedTime;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MealsContainer({
    super.key,
    required this.mealName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.adjustmentType,
    required this.adjustmentValue,
    required this.loggedTime,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<MealsContainer> createState() => _MealsContainerState();
}

class _MealsContainerState extends State<MealsContainer> {
  late String _formattedTime;
  late bool _isSmall;
  late bool _isMedium;
  late bool _isToday;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formattedTime = TimeOfDay.fromDateTime(widget.loggedTime).format(context);
    final screenWidth = MediaQuery.of(context).size.width;
    _isSmall = screenWidth < 350;
    _isMedium = screenWidth < 500;

    final now = DateTime.now();
    _isToday = widget.loggedTime.year == now.year &&
        widget.loggedTime.month == now.month &&
        widget.loggedTime.day == now.day;
  }

  String _getServingInfoText() {
    String info = widget.servingSize;
    if (widget.adjustmentType == 'percent' && widget.adjustmentValue != 100) {
      info += ' (${widget.adjustmentValue.round()}%)';
    } else if (widget.adjustmentType == 'pieces' &&
        widget.adjustmentValue != 1) {
      info +=
          ' (${widget.adjustmentValue.toStringAsFixed(1)} ${widget.adjustmentValue == 1 ? 'piece' : 'pieces'})';
    }
    return info;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: EdgeInsets.all(_isSmall
          ? 16
          : _isMedium
              ? 20
              : 26),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal name and serving info in same row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align items to the center
                children: [
                  // Meal name and serving size with flexible width
                  Flexible(
                    flex: 8, // Allocate 70% of the row's width
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            widget.mealName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: _isSmall
                                  ? 16
                                  : _isMedium
                                      ? 18
                                      : 20,
                            ),
                          ),
                          // Serving info beside the food name (inside scroll)
                          if (widget.servingSize.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                _getServingInfoText(),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: _isSmall ? 8 : 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Popup menu with fixed alignment
                  if (_isToday)
                    IconButton(
                      icon: Icon(Icons.more_vert,
                          size: 20, color: Colors.grey[400]),
                      onPressed: () => _showMenu(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      alignment: Alignment
                          .center, // Align the icon to the center of the row
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Macros rows
              _MacrosRow(
                isSmall: _isSmall,
                calories: widget.calories,
                protein: widget.protein,
              ),
              const SizedBox(height: 8),

              // Carbs/Fats row with time on the right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _MacrosRow(
                      isSmall: _isSmall,
                      carbs: widget.carbs,
                      fat: widget.fat,
                    ),
                  ),
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: _isSmall ? 10 : 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width - 100,
        offset.dy + 40,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      items: [
        /*PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Edit'),
            ],
          ),
        ),*/
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') widget.onEdit();
      if (value == 'delete') widget.onDelete();
    });
  }
}

class _MacrosRow extends StatelessWidget {
  final bool isSmall;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  const _MacrosRow({
    required this.isSmall,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (calories != null && protein != null) ...[
          _MacroChip(
            label: 'Calories',
            value: calories!,
            color: AppColors.caloriesColor,
            fontSize: isSmall ? 8 : 10,
          ),
          _MacroChip(
            label: 'Protein',
            value: protein!,
            color: AppColors.proteinColor,
            fontSize: isSmall ? 8 : 10,
          ),
        ],
        if (carbs != null && fat != null) ...[
          _MacroChip(
            label: 'Carbs',
            value: carbs!,
            color: AppColors.carbsColor,
            fontSize: isSmall ? 8 : 10,
          ),
          _MacroChip(
            label: 'Fats',
            value: fat!,
            color: AppColors.fatColor,
            fontSize: isSmall ? 8 : 10,
          ),
        ],
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double fontSize;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}g',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
