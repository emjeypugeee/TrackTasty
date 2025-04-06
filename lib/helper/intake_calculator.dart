class UserNutritionCalculator {
  final Map<String, dynamic> userData;
  late double bmr;
  late double tdee;
  late double calorieTarget;
  late Map<String, double> macroTargets;

  UserNutritionCalculator(this.userData) {
    _calculateBmr();
    _calculateTdee();
    _setCalorieTarget();
    _setMacroTargets();
  }

  void _calculateBmr() {
    // Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
    final weight = double.parse(userData['weight']);
    final height = double.parse(userData['height']);
    final birthYear = int.parse(userData['timestamp']);
    final age = DateTime.now().year - birthYear;

    if (userData['gender'].toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  void _calculateTdee() {
    // Calculate Total Daily Energy Expenditure based on activity level
    final activityLevel = userData['selectedActivityLevel'];

    // Activity multipliers
    const activityMultipliers = {
      "Not very active": 1.2,
      "Lightly active": 1.375,
      "Moderately active": 1.55,
      "Very active": 1.725,
      "Extremely active": 1.9
    };

    tdee = bmr * (activityMultipliers[activityLevel] ?? 1.2);
  }

  void _setCalorieTarget() {
    // Set daily calorie target based on weight goal
    final currentWeight = double.parse(userData['weight']);
    final goalWeight = double.parse(userData['goalWeight']);

    if (userData['goal'] == 'Lose Weight') {
      // Moderate deficit of 20% for weight loss
      calorieTarget = tdee * 0.8;
    } else if (userData['goal'] == 'Gain Weight') {
      // Moderate surplus of 20% for weight gain
      calorieTarget = tdee * 1.2;
    } else { // Maintain weight
      calorieTarget = tdee;
    }
  }

  void _setMacroTargets() {
    // Set macronutrient targets based on calorie target
    // Protein: 2.2g per kg of body weight (for weight loss)
    final proteinGrams = 2.2 * double.parse(userData['weight']);
    final proteinCalories = proteinGrams * 4;

    // Fat: 25% of total calories
    final fatCalories = calorieTarget * 0.25;
    final fatGrams = fatCalories / 9;

    // Remaining calories go to carbs
    final carbCalories = calorieTarget - proteinCalories - fatCalories;
    final carbGrams = carbCalories / 4;

    macroTargets = {
      'protein': double.parse(proteinGrams.toStringAsFixed(1)),
      'carbs': double.parse(carbGrams.toStringAsFixed(1)),
      'fat': double.parse(fatGrams.toStringAsFixed(1)),
      'calories': calorieTarget.roundToDouble()
    };
  }

  Map<String, double> getDailyTargets() {
    return macroTargets;
  }
}