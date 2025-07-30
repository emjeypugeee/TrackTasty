import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/main_screen_widgets/analytics_screen/bar_graph_container.dart';
import 'package:fitness/widgets/main_screen_widgets/analytics_screen/line_graph_container.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  AnalyticsPage({super.key});

  // Current logged-in user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Future to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!
            .email) // Ensure your Firestore uses email as document ID
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: getUserDetails(),
          builder: (context, snapshot) {
            // Waiting...
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // If there's an error
            if (snapshot.hasError) {
              return Center(child: Text("Error loading profile"));
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data();
              double userWeight =
                  double.tryParse(userData?['weight']?.toString() ?? '0') ??
                      0.0;
              double userGoalWeight =
                  double.tryParse(userData?['goalWeight']?.toString() ?? '0') ??
                      0.0;
              String userGoal = userData?['goal'] ?? "null";

              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight',
                          style: TextStyle(
                              color: AppColors.primaryText, fontSize: 30),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        LineGraphContainer(
                          goalWeight: userGoalWeight,
                          weight: userWeight,
                          goal: userGoal,
                        ),

                        //space
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Calorie Intake',
                          style: TextStyle(
                              color: AppColors.primaryText, fontSize: 30),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        BarGraphContainer()
                      ],
                    ),
                  ),
                ),
              );
            }

            //return if no user found
            return Center(child: Text("User not found"));
          }),
    );
  }
}
