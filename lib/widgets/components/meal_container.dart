import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class MealContainer extends StatelessWidget {
  const MealContainer({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: 100,
      width: screenWidth * 0.92,
      decoration: BoxDecoration(
        color: AppColors.friendsBg,
        borderRadius: BorderRadius.circular(25.0),
      ),
      padding: EdgeInsets.all(10.0),
      child: Row(
        children: [
          Icon(
            Icons.photo,
            color: Colors.white,
            size: 60,
          ),
          SizedBox(
            width: 20,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meal Name',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Calories',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Protein',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Carbs',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Protein',
                    style: TextStyle(color: AppColors.secondaryText),
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
