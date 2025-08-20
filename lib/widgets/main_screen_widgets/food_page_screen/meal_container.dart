import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class MealContainer extends StatelessWidget {
  final String foodName;
  final String foodDescription;
  void Function()? onPressed;
  
  MealContainer(
      {super.key, required this.foodName, required this.foodDescription, required this.onPressed});

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
      padding: EdgeInsets.all(10.0),
      child: SingleChildScrollView(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodName,
                    style:
                        TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    foodDescription,
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
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
      ),
    );
  }
}
