import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/statistics_container.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class ProfileContainer extends StatelessWidget {
  final String name;
  final int joinedDate;
  final String ranking;
  final String following;
  final String userDescription;

  const ProfileContainer(
      {super.key,
      required this.name,
      required this.joinedDate,
      required this.ranking,
      required this.following,
      required this.userDescription});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 410,
      height: 280,
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF262626),
              Color(0xFF413939),
              Color(0xFF363131),
              Color(0xFF302D2D),
              Color(0xFF886868),
            ],
            begin: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.0))),
      padding: EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.titleText),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Joined $joinedDate',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                ],
              )),
              Icon(
                Icons.person_outline,
                size: 100,
                color: Colors.white,
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'Statistics',
            style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatisticsContainer(),
              SizedBox(
                width: 10,
              ),
              StatisticsContainer()
            ],
          )
        ],
      ),
    );
  }
}
