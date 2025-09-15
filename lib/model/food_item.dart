class FoodItem {
  final String mealType;
  final String mealName;
  final String servingSize;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  FoodItem({
    required this.mealType,
    required this.mealName,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toMap() {
    return {
      'mealType': mealType,
      'mealName': mealName,
      'servingSize': servingSize,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Optional: Add fromMap factory constructor for easier deserialization
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      mealType: map['mealType'] ?? '',
      mealName: map['mealName'] ?? '',
      servingSize: map['servingSize'] ?? '',
      calories: map['calories'] ?? 0,
      protein: map['protein'] ?? 0,
      carbs: map['carbs'] ?? 0,
      fat: map['fat'] ?? 0,
    );
  }
}