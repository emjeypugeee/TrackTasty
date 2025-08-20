import 'package:fitness/widgets/main_screen_widgets/food_page_screen/meal_container.dart';
import 'package:fitness/widgets/main_screen_widgets/home_screen/circular_nutrition_progres.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<DateTime> days;
  int selectedIndex = 6;

  final List<Map<String, dynamic>> nutritionData = [
    {'calories': 1800, 'protein': 120, 'carbs': 180, 'fat': 60},
    {'calories': 2000, 'protein': 125, 'carbs': 250, 'fat': 56},
    {'calories': 2200, 'protein': 130, 'carbs': 200, 'fat': 80},
    {'calories': 1600, 'protein': 150, 'carbs': 120, 'fat': 50},
    {'calories': 2400, 'protein': 110, 'carbs': 320, 'fat': 60},
    {'calories': 1900, 'protein': 160, 'carbs': 150, 'fat': 65},
    {'calories': 2700, 'protein': 140, 'carbs': 300, 'fat': 90},
  ];

  final int calorieGoal = 2000;
  final int proteinGoal = 125;
  final int carbsGoal = 250;
  final int fatGoal = 56;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dayFormat = DateFormat('E');
    final DateFormat dateFormat = DateFormat('d');

    // Get nutrition data for the selected day
    final data = nutritionData[selectedIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Calendar for the last 7 days
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isSelected = index == selectedIndex;
                  final dayCalories = nutritionData[index]['calories'] as int;
                  final dayProtein = nutritionData[index]['protein'] as int;
                  final dayCarbs = nutritionData[index]['carbs'] as int;
                  final dayFat = nutritionData[index]['fat'] as int;
                  // Check if the goal is reached
                  final reachedGoal = dayCalories >= calorieGoal;
                  final reachedMacroGoal = reachedGoal &&
                      dayProtein >= proteinGoal &&
                      dayCarbs >= carbsGoal &&
                      dayFat >= fatGoal;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (reachedMacroGoal
                                ? Colors.green
                                : (reachedGoal
                                    ? const Color.fromARGB(255, 150, 136, 17)
                                    : Colors.red))
                            : Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayFormat.format(date),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(date),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[400],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Nutrition progress for selected day
            Row(
              children: [
                // Calories
                Builder(builder: (context) {
                  final calorieDiff = calorieGoal - (data['calories'] as int);
                  final calorieOver = calorieDiff < 0;
                  return CircularNutritionProgres(
                    progress: (data['calories'] as int) / calorieGoal,
                    value: '${calorieOver ? -calorieDiff : calorieDiff}g',
                    label: calorieOver ? 'Calories over' : 'Calories remaining',
                    overGoal: (data['calories'] as int) > calorieGoal,
                  );
                }),
                const SizedBox(width: 10),
                // Protein
                Builder(builder: (context) {
                  final proteinDiff = proteinGoal - (data['protein'] as int);
                  final proteinOver = proteinDiff < 0;
                  return CircularNutritionProgres(
                    progress: (data['protein'] as int) / proteinGoal,
                    value: '${proteinOver ? -proteinDiff : proteinDiff}g',
                    label: proteinOver ? 'Protein over' : 'Protein remaining',
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Carbs
                Builder(builder: (context) {
                  final carbsDiff = carbsGoal - (data['carbs'] as int);
                  final carbsOver = carbsDiff < 0;
                  return CircularNutritionProgres(
                    progress: (data['carbs'] as int) / carbsGoal,
                    value: '${carbsOver ? -carbsDiff : carbsDiff}g',
                    label: carbsOver ? 'Carbs over' : 'Carbs remaining',
                  );
                }),
                const SizedBox(width: 10),
                // Fat
                Builder(builder: (context) {
                  final fatDiff = fatGoal - (data['fat'] as int);
                  final fatOver = fatDiff < 0;
                  return CircularNutritionProgres(
                    progress: (data['fat'] as int) / fatGoal,
                    value: '${fatOver ? -fatDiff : fatDiff}g',
                    label: fatOver ? 'Fat over' : 'Fat remaining',
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Meals:',
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.white, fontSize: 35),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
