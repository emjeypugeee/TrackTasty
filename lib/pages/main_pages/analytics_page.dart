import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/main_screen_widgets/analytics_screen/bar_graph_container.dart';
import 'package:fitness/widgets/main_screen_widgets/analytics_screen/line_graph_container.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import your UserProvider

class AnalyticsPage extends StatefulWidget {
  AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    // Refresh user data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userData == null) {
        userProvider.fetchUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access the UserProvider
    final userProvider = Provider.of<UserProvider>(context);

    // Show loading if user data is not yet loaded
    if (userProvider.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error or empty state if no user data
    if (userProvider.userData == null || userProvider.user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "User data not available",
            style: TextStyle(color: AppColors.primaryText),
          ),
        ),
      );
    }

    // Extract data from provider using the getters you defined
    double userGoalWeight = _parseDouble(userProvider.userData?['goalWeight']);
    String userGoal = userProvider.goal ?? 'Maintain Weight';
    double dailyCalories = _parseDouble(userProvider.userData?['dailyCalories']);

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
                'Nutrition Analysis',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                calorieGoal: dailyCalories,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to parse double values safely
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
