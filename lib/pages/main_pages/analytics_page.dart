import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/main_screen_widgets/analytics_screen/bar_graph_container.dart';
import 'package:fitness/widgets/main_screen_widgets/analytics_screen/line_graph_container.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:fitness/services/weight_forecaster.dart'; // Add this import

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Current logged-in user
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isForecastingEnabled = false;
  Map<String, dynamic>? forecastData;
  bool isLoadingForecast = false;
  bool isProvisionalData = false;

  // Future to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
  }

  // Toggle forecasting
  void toggleForecasting() async {
    final userData = (await getUserDetails()).data();
    if (userData == null) {
      return;
    }

    setState(() {
      isForecastingEnabled = !isForecastingEnabled;
      if (isForecastingEnabled) {
        isLoadingForecast = true;
      } else {
        forecastData = null;
        isProvisionalData = false;
      }
    });

    if (isForecastingEnabled) {
      final forecaster = WeightForecaster(currentUser!.uid);
      final forecast = await forecaster.forecastWeight(
        currentWeight: userData['weight']?.toDouble() ?? 0,
        height: userData['height']?.toDouble() ?? 0,
        age: userData['age'] ?? 0,
        gender: userData['gender'] ?? 'male',
        activityLevel: userData['activityLevel'] ?? 'Sedentary',
        dailyCalorieGoal: userData['dailyCalories']?.toDouble() ?? 2000,
      );

      setState(() {
        forecastData = forecast;
        isProvisionalData = forecast['isProvisionalData'] ?? false;
        isLoadingForecast = false;
      });
    }
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
              return Center(
                  child: Text("Error loading profile",
                      style: TextStyle(color: AppColors.primaryText)));
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data();
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Analytics',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Forecast toggle button
                            ElevatedButton.icon(
                              onPressed: () => toggleForecasting(),
                              icon: isForecastingEnabled
                                  ? Icon(Icons.close)
                                  : Icon(Icons.lightbulb_outline),
                              label: Text(
                                isForecastingEnabled
                                    ? 'Hide Forecast'
                                    : 'Show Forecast',
                                style: TextStyle(
                                  color: isForecastingEnabled
                                      ? AppColors.primaryText
                                      : Colors.blue,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isForecastingEnabled
                                    ? Colors.red[800]
                                    : Colors.grey[800],
                                foregroundColor: AppColors.primaryText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isForecastingEnabled && isProvisionalData)
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'This is provisional data assuming you hit your daily calorie goals consistently. Log more data for personalized forecasts.',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        SizedBox(height: 20),
                        Text(
                          'Calorie Intake',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        BarGraphContainer(
                          calorieGoal:
                              userData?['dailyCalories']?.toDouble() ?? 2000,
                          isForecasting: isForecastingEnabled,
                          forecastData: forecastData,
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Weight Progress',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        LineGraphContainer(
                          goalWeight: userGoalWeight,
                          goal: userGoal,
                          isForecasting: isForecastingEnabled,
                          forecastData: forecastData,
                        ),
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
