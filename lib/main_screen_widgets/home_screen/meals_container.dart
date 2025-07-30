import 'package:flutter/material.dart';

class MealsContainer extends StatelessWidget {
  final String imageUrl; // Can be a network or asset path
  final String mealName;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime loggedTime;

  MealsContainer({
    super.key,
    required this.imageUrl,
    required this.mealName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedTime,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 350;
    final isMedium = screenWidth < 500;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: EdgeInsets.all(isSmall
          ? 10
          : isMedium
              ? 14
              : 20),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Image
              Container(
                width: isSmall
                    ? 40
                    : isMedium
                        ? 52
                        : 64,
                height: isSmall
                    ? 40
                    : isMedium
                        ? 52
                        : 64,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: imageUrl.startsWith('http')
                        ? NetworkImage(imageUrl)
                        : AssetImage(imageUrl) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                  width: isSmall
                      ? 6
                      : isMedium
                          ? 10
                          : 16),
              // Meal Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4), // for spacing below the time
                    Text(
                      mealName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall
                            ? 18
                            : isMedium
                                ? 20
                                : 23,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _MacroChip(
                            label: 'Calories',
                            value: calories,
                            color: Colors.orange,
                            fontSize: isSmall ? 8 : 10),
                        _MacroChip(
                            label: 'Protein',
                            value: protein,
                            color: Colors.blue,
                            fontSize: isSmall ? 8 : 10),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _MacroChip(
                            label: 'Carbs',
                            value: carbs,
                            color: Colors.green,
                            fontSize: isSmall ? 8 : 10),
                        _MacroChip(
                            label: 'Fats',
                            value: fat,
                            color: Colors.purple,
                            fontSize: isSmall ? 8 : 10),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Positioned log time at top right
          Positioned(
            top: 0,
            right: 0,
            child: Text(
              '${TimeOfDay.fromDateTime(loggedTime).format(context)}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final double fontSize;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value\g',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
