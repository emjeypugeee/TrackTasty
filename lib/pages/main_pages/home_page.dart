import 'package:fitness/components/circular_day_progress.dart';
import 'package:fitness/components/circular_nutrition_progres.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF121212),
        automaticallyImplyLeading: false,
        title: Text(
          'TrackTasty',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Color(0xFFE99797),
            fontSize: 30,
          ),
        ),
      ),
      backgroundColor: Color(0xFF121212),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircularDayProgress(day: 'S', progress: 0.2),
                CircularDayProgress(day: 'M', progress: 1),
                CircularDayProgress(day: 'T', progress: 0.5),
                CircularDayProgress(day: 'W', progress: 1),
                CircularDayProgress(day: 'Th', progress: 0.7),
                CircularDayProgress(day: 'F', progress: 1),
                CircularDayProgress(day: 'S', progress: 0.2),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                CircularNutritionProgres(
                    progress: 0.5, value: '1830', label: 'Carolies left'),
                SizedBox(
                  width: 10,
                ),
                CircularNutritionProgres(
                    progress: 0.5, value: '209g', label: 'Protein left'),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                CircularNutritionProgres(
                    progress: 0.5, value: '83g', label: 'Carbs left'),
                SizedBox(width: 10),
                CircularNutritionProgres(
                    progress: 0.5, value: '77g', label: 'Fat left'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
