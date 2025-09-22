import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class MealContainer extends StatelessWidget {
  final String foodName;
  final String foodDescription;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String serving;
  final void Function()? onPressed;

  const MealContainer({
    super.key,
    required this.foodName,
    required this.foodDescription,
    required this.onPressed,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.serving,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: 90,
      width: screenWidth * 0.92,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.friendsBg,
        borderRadius: BorderRadius.circular(25.0),
      ),
      padding: EdgeInsets.all(15.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal scroll for food name
                SizedBox(
                  height: 20,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      foodName,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                // Vertical scroll for food description
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Text(
                      foodDescription,
                      style: TextStyle(
                          color: AppColors.secondaryText, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
              child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              Icons.add,
            ),
            color: Colors.white,
          ))
        ],
      ),
    );
  }
}
