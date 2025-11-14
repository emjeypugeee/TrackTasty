import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:fitness/widgets/components/my_buttons.dart';

class GoalCelebrationDialog extends StatelessWidget {
  final Map<String, dynamic> achievementData;

  const GoalCelebrationDialog({required this.achievementData});

  @override
  Widget build(BuildContext context) {
    final goalType = achievementData['goalType'];
    final initialWeight = achievementData['initialWeight'];
    final goalWeight = achievementData['goalWeight'];
    final achievedWeight = achievementData['achievedWeight'];
    final isMetric = achievementData['measurementSystem'] == 'Metric';
    final unit = isMetric ? 'kg' : 'lbs';

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.yellow.withOpacity(0.7),
          width: 3,
        ),
      ),
      title: Center(
        child: Text(
          '🎉 Goal Achieved! 🎉',
          style: TextStyle(
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Celebration icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                size: 60,
                color: Colors.yellow,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Achievement message
          Text(
            'Congratulations! You have successfully reached your $goalType goal!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Progress details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Starting Weight:',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      '$initialWeight $unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Goal Weight:',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      '$goalWeight $unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Achieved Weight:',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      '$achievedWeight $unit',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Success message
          Text(
            'This amazing achievement has been recorded in your profile! Ready for your next challenge?',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showEditGoalSheet(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.yellow.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Set New Goal',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close celebration dialog
                  // Navigate to profile page
                  context.go('/profile');

                  // Force refresh the profile page to show new achievement
                  final userProvider = context.read<UserProvider>();
                  userProvider.notifyListeners();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Celebrate!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }

  void _showEditGoalSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch user data
    FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get()
        .then((doc) {
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;

        // Controllers and variables for form fields
        TextEditingController weightController = TextEditingController();
        TextEditingController heightController = TextEditingController();
        TextEditingController goalWeightController = TextEditingController();
        TextEditingController ageController = TextEditingController();

        String? selectedGender;
        String? selectedActivityLevel;
        String? selectedGoal;

        // Initialize with current values
        weightController.text = userData['weight']?.toString() ?? '';
        heightController.text = userData['height']?.toString() ?? '';
        goalWeightController.text = userData['goalWeight'].toString() ?? '';
        ageController.text = userData['age']?.toString() ?? '';
        selectedGender = userData['gender'] ?? 'male';
        selectedActivityLevel =
            userData['selectedActivityLevel'] ?? 'Sedentary';
        selectedGoal = userData['goal'] ?? 'Maintain Weight';

        // Check if user uses metric system
        final bool isMetric = userData['measurementSystem'] == 'Metric';

        // Track if goal weight field should be enabled
        bool isGoalWeightEnabled = selectedGoal != 'Maintain Weight';

        // Create form key for validation
        final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.containerBg,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              // Function to show goal weight suggestions - MOVED INSIDE StatefulBuilder
              void showGoalWeightSuggestions() {
                if (weightController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter your current weight first'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final currentWeight = double.tryParse(weightController.text);
                if (currentWeight == null) return;

                List<Map<String, dynamic>> suggestions = [];

                if (selectedGoal == 'Lose Weight' ||
                    selectedGoal == 'Mild Lose Weight') {
                  suggestions = [
                    {'label': 'Mild Loss (-5%)', 'value': currentWeight * 0.95},
                    {
                      'label': 'Moderate Loss (-10%)',
                      'value': currentWeight * 0.90
                    },
                    {
                      'label': 'Significant Loss (-15%)',
                      'value': currentWeight * 0.85
                    },
                  ];
                } else if (selectedGoal == 'Gain Weight' ||
                    selectedGoal == 'Mild Gain Weight') {
                  suggestions = [
                    {'label': 'Mild Gain (+5%)', 'value': currentWeight * 1.05},
                    {
                      'label': 'Moderate Gain (+10%)',
                      'value': currentWeight * 1.10
                    },
                    {
                      'label': 'Significant Gain (+15%)',
                      'value': currentWeight * 1.15
                    },
                  ];
                } else {
                  // For maintain weight, just use the current weight
                  goalWeightController.text = currentWeight.toStringAsFixed(1);
                  return;
                }

                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.containerBg,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Suggested Goal Weights',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Based on your current weight and goal',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 20),
                        ...suggestions.map((suggestion) => ListTile(
                              title: Text(
                                suggestion['label'],
                                style: TextStyle(color: AppColors.primaryText),
                              ),
                              trailing: Text(
                                '${suggestion['value'].toStringAsFixed(1)} ${isMetric ? 'kg' : 'lb'}',
                                style: TextStyle(
                                  color: AppColors.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  goalWeightController.text =
                                      suggestion['value'].toStringAsFixed(1);
                                });
                                Navigator.pop(context);
                              },
                            )),
                        SizedBox(height: 20),
                        MyButtons(
                          text: 'Cancel',
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Function to validate goal weight based on current weight and selected goal
              String? validateGoalWeight(String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your goal weight';
                }

                final goalWeight = double.tryParse(value) ?? 0;
                final currentWeight =
                    double.tryParse(weightController.text) ?? 0;

                // Basic range validation
                if (isMetric && (goalWeight < 20 || goalWeight > 300)) {
                  return 'Goal weight should be around 20-300 kg';
                } else if (!isMetric && (goalWeight < 40 || goalWeight > 660)) {
                  return 'Goal weight should be around 40-660 lbs';
                }

                // Validate format: 1-3 digits, optional decimal, 0-2 decimal digits
                final regex = RegExp(r'^\d{1,3}(\.\d{0,2})?$');
                if (!regex.hasMatch(value)) {
                  return 'Invalid format';
                }

                // Validate total length
                if (value.length > 6) {
                  return 'Max 6 chars';
                }

                // Goal-specific validation
                if (selectedGoal == 'Gain Weight' ||
                    selectedGoal == 'Mild Gain Weight') {
                  if (goalWeight <= currentWeight) {
                    return 'Goal weight must be higher than current weight for weight gain goals';
                  }
                } else if (selectedGoal == 'Lose Weight' ||
                    selectedGoal == 'Mild Lose Weight') {
                  if (goalWeight >= currentWeight) {
                    return 'Goal weight must be lower than current weight for weight loss goals';
                  }
                } else if (selectedGoal == 'Maintain Weight') {
                  // For maintain weight, goal weight should equal current weight
                  if (goalWeight != currentWeight) {
                    return 'Goal weight should equal current weight for maintenance';
                  }
                }

                return null;
              }

              // Function to handle goal changes
              void handleGoalChange(String? newGoal) {
                setState(() {
                  selectedGoal = newGoal;
                  isGoalWeightEnabled = newGoal != 'Maintain Weight';

                  // If goal is Maintain Weight, auto-fill goal weight with current weight
                  if (newGoal == 'Maintain Weight') {
                    goalWeightController.text = weightController.text;
                  }
                });
              }

              return Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Center(
                      child: Text(
                        'Update Your Information',
                        style: TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Scrollable form content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Age Field
                              Text(
                                'Age',
                                style: TextStyle(
                                    color: AppColors.primaryText, fontSize: 16),
                              ),
                              TextFormField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter your age',
                                  filled: true,
                                  fillColor: AppColors.textFieldBg,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r"[0-9\']")),
                                  LengthLimitingTextInputFormatter(3),
                                  _MacroInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your age';
                                  }
                                  final age = double.tryParse(value) ?? 0;
                                  if (age < 14 || age > 80) {
                                    return 'Age can only range from 14-80';
                                  }

                                  // Validate total length
                                  if (value.length > 3) {
                                    return 'Max 3 chars';
                                  }
                                  return null;
                                },
                                style: TextStyle(color: AppColors.primaryText),
                              ),
                              const SizedBox(height: 15),

                              // Weight Field
                              Text(
                                'Weight (${isMetric ? 'kg' : 'lbs'})',
                                style: TextStyle(
                                    color: AppColors.primaryText, fontSize: 16),
                              ),
                              TextFormField(
                                controller: weightController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter your weight',
                                  filled: true,
                                  fillColor: AppColors.textFieldBg,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r"[0-9\.']")),
                                  LengthLimitingTextInputFormatter(6),
                                  _MacroInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your weight';
                                  }
                                  final weight = double.tryParse(value) ?? 0;
                                  if (isMetric &&
                                      (weight < 20 || weight > 300)) {
                                    return 'Weight should be around 20-300 kg';
                                  } else if (!isMetric &&
                                      (weight < 40 || weight > 660)) {
                                    return 'Weight should be around 40-660 lbs';
                                  }
                                  // Validate format: 1-3 digits, optional decimal, 0-2 decimal digits
                                  final regex =
                                      RegExp(r'^\d{1,3}(\.\d{0,2})?$');
                                  if (!regex.hasMatch(value)) {
                                    return 'Invalid format';
                                  }

                                  // Validate total length
                                  if (value.length > 6) {
                                    return 'Max 6 chars';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // When weight changes and goal is Maintain Weight, update goal weight
                                  if (selectedGoal == 'Maintain Weight') {
                                    setState(() {
                                      goalWeightController.text = value;
                                    });
                                  }
                                },
                                style: TextStyle(color: AppColors.primaryText),
                              ),
                              const SizedBox(height: 15),

                              // Goal Weight Field with Suggest Button
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Goal Weight (${isMetric ? 'kg' : 'lbs'})',
                                      style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 7, // 70% width
                                    child: TextFormField(
                                      controller: goalWeightController,
                                      keyboardType: TextInputType.number,
                                      enabled: isGoalWeightEnabled,
                                      decoration: InputDecoration(
                                        hintText: isGoalWeightEnabled
                                            ? 'Enter your goal weight'
                                            : 'Auto-filled for maintenance',
                                        filled: true,
                                        fillColor: isGoalWeightEnabled
                                            ? AppColors.textFieldBg
                                            : Colors.grey[600],
                                        hintStyle: TextStyle(
                                          color: isGoalWeightEnabled
                                              ? null
                                              : Colors.grey[400],
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r"[0-9\.']")),
                                        LengthLimitingTextInputFormatter(6),
                                        _MacroInputFormatter(),
                                      ],
                                      validator: validateGoalWeight,
                                      style: TextStyle(
                                        color: isGoalWeightEnabled
                                            ? AppColors.primaryText
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 3, // 30% width
                                    child: ElevatedButton(
                                      onPressed: isGoalWeightEnabled
                                          ? showGoalWeightSuggestions
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 15),
                                      ),
                                      child: Text(
                                        'Suggest',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Height Field
                              Text(
                                'Height (${isMetric ? 'cm' : 'inches'})',
                                style: TextStyle(
                                    color: AppColors.primaryText, fontSize: 16),
                              ),
                              TextFormField(
                                controller: heightController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter your height',
                                  filled: true,
                                  fillColor: AppColors.textFieldBg,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r"[0-9\.']")),
                                  LengthLimitingTextInputFormatter(6),
                                  _MacroInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your height';
                                  }

                                  if (isMetric) {
                                    final height = double.tryParse(value) ?? 0;
                                    if (height < 50 || height > 300) {
                                      return 'Height should be between 50-300 cm';
                                    }
                                  } else {
                                    double totalInches;

                                    if (value.contains("'")) {
                                      final parts = value.split("'");
                                      if (parts.length != 2 ||
                                          parts[1].isEmpty) {
                                        return 'Use format: feet\'inches (e.g. 5\'3)';
                                      }

                                      final feet =
                                          double.tryParse(parts[0]) ?? -1;
                                      final inches =
                                          double.tryParse(parts[1]) ?? -1;

                                      if (feet < 1 || feet > 10) {
                                        return 'Feet should be between 1-10';
                                      }
                                      if (inches < 0 || inches >= 12) {
                                        return 'Inches should be between 0-11.99';
                                      }
                                      totalInches = feet * 12 + inches;
                                    } else {
                                      totalInches = double.tryParse(value) ?? 0;
                                    }

                                    // Validate format: 1-3 digits, optional decimal, 0-2 decimal digits
                                    final regex =
                                        RegExp(r'^\d{1,3}(\.\d{0,2})?$');
                                    if (!regex.hasMatch(value)) {
                                      return 'Invalid format';
                                    }

                                    // Validate total length
                                    if (value.length > 6) {
                                      return 'Max 6 chars';
                                    }

                                    if (totalInches < 20 || totalInches > 120) {
                                      return 'Height should be between 20-120 inches';
                                    }
                                  }
                                  return null;
                                },
                                style: TextStyle(color: AppColors.primaryText),
                              ),
                              const SizedBox(height: 15),

                              // Gender Dropdown
                              Text(
                                'Gender',
                                style: TextStyle(
                                    color: AppColors.primaryText, fontSize: 16),
                              ),
                              DropdownButtonFormField<String>(
                                value: selectedGender,
                                dropdownColor:
                                    const Color.fromARGB(255, 15, 15, 15),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.textFieldBg,
                                ),
                                style: TextStyle(color: AppColors.primaryText),
                                items: ['male', 'female']
                                    .map((gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender == 'male'
                                              ? 'Male'
                                              : 'Female'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedGender = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your gender';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              // Activity Level Dropdown
                              Text(
                                'Activity Level',
                                style: TextStyle(
                                    color: AppColors.primaryText, fontSize: 16),
                              ),
                              DropdownButtonFormField<String>(
                                value: selectedActivityLevel,
                                dropdownColor:
                                    const Color.fromARGB(255, 15, 15, 15),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.textFieldBg,
                                ),
                                style: TextStyle(color: AppColors.primaryText),
                                items: [
                                  'Sedentary',
                                  'Lightly active',
                                  'Moderately active',
                                  'Very active',
                                  'Extra active'
                                ]
                                    .map((level) => DropdownMenuItem(
                                          value: level,
                                          child: Text(level),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedActivityLevel = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your activity level';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              // Goal Dropdown
                              Text(
                                'Goal',
                                style: TextStyle(
                                    color: AppColors.primaryText, fontSize: 16),
                              ),
                              DropdownButtonFormField<String>(
                                value: selectedGoal,
                                dropdownColor:
                                    const Color.fromARGB(255, 15, 15, 15),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.textFieldBg,
                                ),
                                style: TextStyle(color: AppColors.primaryText),
                                items: [
                                  'Mild Lose Weight',
                                  'Lose Weight',
                                  'Maintain Weight',
                                  'Mild Gain Weight',
                                  'Gain Weight'
                                ]
                                    .map((goal) => DropdownMenuItem(
                                          value: goal,
                                          child: Text(goal),
                                        ))
                                    .toList(),
                                onChanged: handleGoalChange,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your goal';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Buttons at the bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: CustomTextButton(
                            title: 'Cancel',
                            onTap: () => Navigator.pop(context),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: MyButtons(
                            text: 'Recalculate',
                            onTap: () async {
                              // Validate all form fields before proceeding
                              if (_formKey.currentState!.validate()) {
                                debugPrint(
                                    "✅ Form validated, preparing data...");

                                // Prepare the data
                                final newWeight =
                                    double.tryParse(weightController.text) ??
                                        userData['weight'];
                                final Map<String, dynamic> updatedUserData =
                                    Map.from(userData);
                                updatedUserData['age'] =
                                    int.tryParse(ageController.text) ??
                                        userData['age'];
                                updatedUserData['weight'] = newWeight;

                                // For Maintain Weight, ensure goal weight equals current weight
                                final goalWeight =
                                    selectedGoal == 'Maintain Weight'
                                        ? newWeight
                                        : double.tryParse(
                                                goalWeightController.text) ??
                                            userData['goalWeight'];

                                updatedUserData['goalWeight'] = goalWeight;
                                updatedUserData['height'] =
                                    double.tryParse(heightController.text) ??
                                        userData['height'];
                                updatedUserData['gender'] = selectedGender;
                                updatedUserData['selectedActivityLevel'] =
                                    selectedActivityLevel;
                                updatedUserData['goal'] = selectedGoal;

                                debugPrint(
                                    "🎯 Attempting navigation to /recalcmacros...");

                                // Try navigation first, then close the sheet
                                try {
                                  // Navigate without closing the sheet first
                                  final result = await context
                                      .push('/recalcmacros', extra: {
                                    'userData': updatedUserData,
                                    'selectedGoal': selectedGoal!,
                                  });

                                  debugPrint(
                                      "✅ Navigation successful, closing bottom sheet");

                                  // Now close the bottom sheet
                                  Navigator.pop(context);
                                } catch (e) {
                                  debugPrint("❌ Navigation failed: $e");
                                  // If navigation fails, show error but keep the sheet open
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to navigate: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // Show error message if validation fails
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please fix all errors before recalculating'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      }
    });
  }
}

class _MacroInputFormatter extends TextInputFormatter {
  final RegExp _validFormat = RegExp(r'^\d{0,3}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    if (_validFormat.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}
