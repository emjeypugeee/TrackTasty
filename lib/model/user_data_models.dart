class UserRegistrationData {
  String? username;
  int? age;
  String? gender;
  String? activityLevel;
  String? goal;
  double? height;
  double? weight;
  double? goalWeight;
  String? measurementSystem;
  String? dietaryPreference;
  List<String> allergies = [];
  double? dailyCalories;
  double? carbsPercentage;
  double? fatsPercentage;
  double? proteinPercentage;
  double? carbsGram;
  double? fatsGram;
  double? proteinGram;
  String? email;
  String? password;

  UserRegistrationData();

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
      'goal': goal,
      'height': height,
      'weight': weight,
      'goalWeight': goalWeight,
      'measurementSystem': measurementSystem,
      'dietaryPreference': dietaryPreference,
      'allergies': allergies,
      'dailyCalories': dailyCalories,
      'carbsPercentage': carbsPercentage,
      'fatsPercentage': fatsPercentage,
      'proteinPercentage': proteinPercentage,
      'carbsGram': carbsGram,
      'fatsGram': fatsGram,
      'proteinGram': proteinGram,
      'email': email,
    };
  }

  static UserRegistrationData fromMap(Map<String, dynamic> map) {
    final data = UserRegistrationData();
    data.username = map['username'];
    data.age = map['age'];
    data.gender = map['gender'];
    data.activityLevel = map['activityLevel'];
    data.goal = map['goal'];
    data.height = map['height'];
    data.weight = map['weight'];
    data.goalWeight = map['goalWeight'];
    data.measurementSystem = map['measurementSystem'];
    data.dietaryPreference = map['dietaryPreference'];
    data.allergies = List<String>.from(map['allergies'] ?? []);
    data.dailyCalories = map['dailyCalories'];
    data.carbsPercentage = map['carbsPercentage'];
    data.fatsPercentage = map['fatsPercentage'];
    data.proteinPercentage = map['proteinPercentage'];
    data.carbsGram = map['carbsGram'];
    data.fatsGram = map['fatsGram'];
    data.proteinGram = map['proteinGram'];
    data.email = map['email'];
    return data;
  }
}
