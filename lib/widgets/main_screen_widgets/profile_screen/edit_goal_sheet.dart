import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/utils/goal_achievement_utils.dart';

class EditGoalSheet extends StatefulWidget {
  final VoidCallback? onGoalUpdated;

  const EditGoalSheet({super.key, this.onGoalUpdated});

  @override
  State<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<EditGoalSheet> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isMetric = false;
  bool _isLoading = true;

  // Controllers and variables for form fields
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _goalWeightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _selectedGender;
  String? _selectedActivityLevel;
  String? _selectedGoal;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isGoalWeightEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null || _user!.email == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_user!.email)
          .get();

      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;

        setState(() {
          _isMetric = userData['measurementSystem'] == "Metric";

          // Initialize with current values
          _weightController.text = userData['weight']?.toString() ?? '';
          _heightController.text = userData['height']?.toString() ?? '';
          _goalWeightController.text = userData['goalWeight'].toString() ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _selectedGender = userData['gender'] ?? 'male';
          _selectedActivityLevel =
              userData['selectedActivityLevel'] ?? 'Sedentary';
          _selectedGoal = userData['goal'] ?? 'Maintain Weight';
          _isGoalWeightEnabled = _selectedGoal != 'Maintain Weight';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() => _isLoading = false);
    }
  }

  // Function to show goal weight suggestions
  void _showGoalWeightSuggestions() {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your current weight first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentWeight = double.tryParse(_weightController.text);
    if (currentWeight == null) return;

    List<Map<String, dynamic>> suggestions = [];

    if (_selectedGoal == 'Lose Weight' || _selectedGoal == 'Mild Lose Weight') {
      suggestions = [
        {'label': 'Mild Loss (-5%)', 'value': currentWeight * 0.95},
        {'label': 'Moderate Loss (-10%)', 'value': currentWeight * 0.90},
        {'label': 'Significant Loss (-15%)', 'value': currentWeight * 0.85},
      ];
    } else if (_selectedGoal == 'Gain Weight' ||
        _selectedGoal == 'Mild Gain Weight') {
      suggestions = [
        {'label': 'Mild Gain (+5%)', 'value': currentWeight * 1.05},
        {'label': 'Moderate Gain (+10%)', 'value': currentWeight * 1.10},
        {'label': 'Significant Gain (+15%)', 'value': currentWeight * 1.15},
      ];
    } else {
      // For maintain weight, just use the current weight
      _goalWeightController.text = currentWeight.toStringAsFixed(1);
      setState(() {});
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.containerBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    '${suggestion['value'].toStringAsFixed(1)} ${_isMetric ? 'kg' : 'lb'}',
                    style: TextStyle(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _goalWeightController.text =
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

  // Function to handle goal changes
  void _handleGoalChange(String? newGoal) {
    setState(() {
      _selectedGoal = newGoal;
      _isGoalWeightEnabled = newGoal != 'Maintain Weight';

      // If goal is Maintain Weight, auto-fill goal weight with current weight
      if (newGoal == 'Maintain Weight') {
        _goalWeightController.text = _weightController.text;
      }
    });
  }

  // Function to validate goal weight based on current weight and selected goal
  String? _validateGoalWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your goal weight';
    }

    final goalWeight = double.tryParse(value) ?? 0;
    final currentWeight = double.tryParse(_weightController.text) ?? 0;

    // Basic range validation
    if (_isMetric && (goalWeight < 20 || goalWeight > 300)) {
      return 'Goal weight should be around 20-300 kg';
    } else if (!_isMetric && (goalWeight < 40 || goalWeight > 660)) {
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
    if (_selectedGoal == 'Gain Weight' || _selectedGoal == 'Mild Gain Weight') {
      if (goalWeight <= currentWeight) {
        return 'Goal weight must be higher than current weight for weight gain goals';
      }
    } else if (_selectedGoal == 'Lose Weight' ||
        _selectedGoal == 'Mild Lose Weight') {
      if (goalWeight >= currentWeight) {
        return 'Goal weight must be lower than current weight for weight loss goals';
      }
    } else if (_selectedGoal == 'Maintain Weight') {
      // For maintain weight, goal weight should equal current weight
      if (goalWeight != currentWeight) {
        return 'Goal weight should equal current weight for maintenance';
      }
    }

    return null;
  }

  void _recalculateMacros() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all errors before recalculating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_user == null || _user!.email == null) return;

    // Update initial weight when goal changes
    final newWeight = double.tryParse(_weightController.text) ?? 0;
    final goalWeight = double.tryParse(_goalWeightController.text) ?? 0;

    // Save the new goal using GoalAchievementUtils
    await GoalAchievementUtils.saveUserGoal(
      userId: _user!.uid,
      userEmail: _user!.email!,
      goalType: _selectedGoal!,
      goalWeight: goalWeight,
      currentWeight: newWeight,
      measurementSystem: _isMetric ? 'Metric' : 'Imperial',
    );

    // Update user weight in Firestore
    await FirebaseFirestore.instance.collection('Users').doc(_user!.email).set({
      'weight': newWeight,
    }, SetOptions(merge: true));

    // Create updated user data with the new values
    final updatedUserData = {
      'age': int.tryParse(_ageController.text),
      'weight': newWeight,
      'goalWeight': goalWeight,
      'height': double.tryParse(_heightController.text),
      'gender': _selectedGender,
      'selectedActivityLevel': _selectedActivityLevel,
      'goal': _selectedGoal,
    };

    // Call the callback if provided
    widget.onGoalUpdated?.call();

    // Navigate to the recalculate macros page
    if (context.mounted) {
      Navigator.pop(context); // Close the bottom sheet
      context.push('/recalcmacros', extra: {
        'userData': updatedUserData,
        'selectedGoal': _selectedGoal!,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                fontSize: 24,
              ),
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
                    _buildFormField(
                      label: 'Age',
                      controller: _ageController,
                      hintText: 'Enter your age',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        final age = double.tryParse(value) ?? 0;
                        if (age < 14 || age > 80) {
                          return 'Age can only range from 14-80';
                        }
                        if (value.length > 3) {
                          return 'Max 3 chars';
                        }
                        return null;
                      },
                    ),

                    // Weight Field
                    _buildFormField(
                      label: 'Weight (${_isMetric ? 'kg' : 'lbs'})',
                      controller: _weightController,
                      hintText: 'Enter your weight',
                      validator: (value) => _validateWeight(value),
                      onChanged: (value) {
                        // When weight changes and goal is Maintain Weight, update goal weight
                        if (_selectedGoal == 'Maintain Weight') {
                          setState(() {
                            _goalWeightController.text = value;
                          });
                        }
                      },
                    ),

                    // Goal Weight Field with Suggest Button
                    _buildGoalWeightField(),

                    // Height Field
                    _buildFormField(
                      label: 'Height (${_isMetric ? 'cm' : 'inches'})',
                      controller: _heightController,
                      hintText: 'Enter your height',
                      validator: _validateHeight,
                    ),

                    // Gender Dropdown
                    _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: ['male', 'female'],
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                      displayText: (value) =>
                          value == 'male' ? 'Male' : 'Female',
                    ),

                    // Activity Level Dropdown
                    _buildDropdown(
                      label: 'Activity Level',
                      value: _selectedActivityLevel,
                      items: [
                        'Sedentary',
                        'Lightly active',
                        'Moderately active',
                        'Very active',
                        'Extra active'
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedActivityLevel = value),
                    ),

                    // Goal Dropdown
                    _buildDropdown(
                      label: 'Goal',
                      value: _selectedGoal,
                      items: [
                        'Mild Lose Weight',
                        'Lose Weight',
                        'Maintain Weight',
                        'Mild Gain Weight',
                        'Gain Weight'
                      ],
                      onChanged: _handleGoalChange,
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
                  onTap: _recalculateMacros,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.textFieldBg,
          ),
          inputFormatters: [
            if (label.contains('Height'))
              FilteringTextInputFormatter.allow(RegExp(r"[0-9\']"))
            else
              FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
            _MacroInputFormatter(),
          ],
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(color: AppColors.primaryText),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildGoalWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Goal Weight (${_isMetric ? 'kg' : 'lbs'})',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
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
                controller: _goalWeightController,
                keyboardType: TextInputType.number,
                enabled: _isGoalWeightEnabled,
                decoration: InputDecoration(
                  hintText: _isGoalWeightEnabled
                      ? 'Enter your goal weight'
                      : 'Auto-filled for maintenance',
                  filled: true,
                  fillColor: _isGoalWeightEnabled
                      ? AppColors.textFieldBg
                      : Colors.grey[600],
                  hintStyle: TextStyle(
                    color: _isGoalWeightEnabled ? null : Colors.grey[400],
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[0-9\.']")),
                  LengthLimitingTextInputFormatter(6),
                  _MacroInputFormatter(),
                ],
                validator: _validateGoalWeight,
                style: TextStyle(
                  color: _isGoalWeightEnabled
                      ? AppColors.primaryText
                      : Colors.grey[400],
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 3, // 30% width
              child: ElevatedButton(
                onPressed:
                    _isGoalWeightEnabled ? _showGoalWeightSuggestions : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String Function(String)? displayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color.fromARGB(255, 15, 15, 15),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: AppColors.textFieldBg,
          ),
          style: TextStyle(color: AppColors.primaryText),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(displayText != null ? displayText(item) : item),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your ${label.toLowerCase()}';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your weight';
    }
    final weight = double.tryParse(value) ?? 0;
    if (_isMetric && (weight < 20 || weight > 300)) {
      return 'Weight should be around 20-300 kg';
    } else if (!_isMetric && (weight < 40 || weight > 660)) {
      return 'Weight should be around 40-660 lbs';
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
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your height';
    }

    if (_isMetric) {
      final height = double.tryParse(value) ?? 0;
      if (height < 50 || height > 300) {
        return 'Height should be between 50-300 cm';
      }
    } else {
      double totalInches;

      if (value.contains("'")) {
        final parts = value.split("'");
        if (parts.length != 2 || parts[1].isEmpty) {
          return 'Use format: feet\'inches (e.g. 5\'3)';
        }

        final feet = double.tryParse(parts[0]) ?? -1;
        final inches = double.tryParse(parts[1]) ?? -1;

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

      final regex = RegExp(r'^\d{1,3}(\.\d{0,2})?$');
      if (!regex.hasMatch(value)) {
        return 'Invalid format';
      }

      if (value.length > 6) {
        return 'Max 6 chars';
      }

      if (totalInches < 20 || totalInches > 120) {
        return 'Height should be between 20-120 inches';
      }
    }
    return null;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _goalWeightController.dispose();
    _ageController.dispose();
    super.dispose();
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

// Utility function to show the EditGoalSheet
void showEditGoalSheet(BuildContext context, {VoidCallback? onGoalUpdated}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.containerBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => EditGoalSheet(onGoalUpdated: onGoalUpdated),
  );
}
