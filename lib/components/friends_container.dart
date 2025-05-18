import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class FriendsContainer extends StatelessWidget {
  const FriendsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: 410,
      decoration: BoxDecoration(
        color: AppColors.friendsBg,
        borderRadius: BorderRadius.circular(25.0),
      ),
      padding: EdgeInsets.all(10.0),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_outlined,
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
                'Friend Name',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '?? Day(s) streak',
                style: TextStyle(color: Colors.grey[600]),
              )
            ],
          )
        ],
      ),
    );
  }
}
