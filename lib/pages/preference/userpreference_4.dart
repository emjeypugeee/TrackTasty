import 'package:fitness/provider/registration_data_provider.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

const List<Widget> units = <Widget>[
  Text('Imperial'),
  Text('Metric'),
];

class Userpreference4 extends StatefulWidget {
  const Userpreference4({super.key});

  @override
  State<Userpreference4> createState() => _Userpreference4();
}

class _Userpreference4 extends State<Userpreference4> {
  //to track the state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  //Height, Weight and goal weight
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController goalWeightController = TextEditingController();

  bool _isMetric = true;
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _goalWeightFocusNode = FocusNode();

  //to track the measurement system
  final List<bool> _selectedUnits = <bool>[true, false];
  bool isMetric = false;

  // Goal
  String? _goal = 'Maintain Weight';

  @override
  void initState() {
    super.initState();

    _loadData();

    weightController.addListener(() {
      if (_goal == 'Maintain Weight') {
        goalWeightController.text = weightController.text;
      }
    });

    _heightFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_heightFocusNode.hasFocus) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    await provider.loadFromPreferences(); // Load data from SharedPreferences

    // Pre-fill body metrics if available
    heightController.text = provider.userData.height?.toString() ?? '';
    weightController.text = provider.userData.weight?.toString() ?? '';
    goalWeightController.text = provider.userData.goalWeight?.toString() ?? '';
    isMetric = provider.userData.measurementSystem == 'Metric';
    _goal = provider.userData.goal?.toString() ?? 'Maintain Weight';

    setState(() {}); // Update the UI after loading data
  }

  //saving user height, weight and goalweight
  Future<void> saveUserGoal() async {
    double? height;
    double? weight;
    double? goalWeight;

    // Parse height based on measurement system
    if (heightController.text.isNotEmpty) {
      if (isMetric) {
        // Metric: simple decimal parsing
        height = double.tryParse(heightController.text);
      } else {
        // Imperial: handle feet'inches format
        final value = heightController.text.trim().replaceAll('"', '');

        if (value.contains("'")) {
          final parts = value.split("'");
          if (parts.length == 2 && parts[1].isNotEmpty) {
            final feet = double.tryParse(parts[0]) ?? 0;
            final inches = double.tryParse(parts[1]) ?? 0;
            height = (feet * 12) + inches; // Convert to total inches
          }
        } else {
          // Plain inches format
          height = double.tryParse(value);
        }
      }
    }

    // Parse weight and goal weight
    if (weightController.text.isNotEmpty) {
      weight = double.tryParse(weightController.text);
    }

    if (goalWeightController.text.isNotEmpty) {
      goalWeight = double.tryParse(goalWeightController.text);
    }

    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);

    provider.updateBodyMetrics(
      height: height,
      weight: weight,
      goalWeight: goalWeight,
      isMetric: isMetric,
    );
  }

  void _convertUnits(int index) {
    // Check if the user is actually changing the unit system
    bool newIsMetric = index == 1;

    // If the user is clicking the same unit that's already selected, do nothing
    if (newIsMetric == isMetric) {
      return;
    }

    final hadFocus = _heightFocusNode.hasFocus;

    setState(() {
      for (int i = 0; i < _selectedUnits.length; i++) {
        _selectedUnits[i] = i == index;
      }
      _isMetric = newIsMetric;
      isMetric = newIsMetric;

      // Only convert if the unit system actually changed
      _performUnitConversion();
    });

    if (hadFocus) {
      _heightFocusNode.unfocus();

      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _heightFocusNode.requestFocus();
        }
      });
    }

    debugPrint(isMetric ? "Using Metric" : "Using US");
  }

  void _performUnitConversion() {
    // Height conversion logic
    if (heightController.text.isNotEmpty) {
      if (isMetric) {
        // Convert from Imperial (in) to Metric (cm)
        double totalInches = 0;
        final value = heightController.text.trim().replaceAll('"', '');

        // Check for the feet'inches format (e.g., 5'11, 5'11.5)
        final feetInchesRegExp = RegExp(r"^(\d+)'(\d+(?:\.\d+)?)$");
        final feetInchesMatch = feetInchesRegExp.firstMatch(value);

        if (feetInchesMatch != null) {
          final feet = double.tryParse(feetInchesMatch.group(1)!) ?? 0;
          final inches = double.tryParse(feetInchesMatch.group(2)!) ?? 0;
          totalInches = (feet * 12) + inches;
        } else {
          // Handle plain inches format (e.g., 71, 71.5)
          totalInches = double.tryParse(value) ?? 0;
        }

        final cm = totalInches * 2.54;
        heightController.text = cm.toStringAsFixed(1);
      } else {
        // Convert from Metric (cm) to Imperial (ft'in)
        final cm = double.tryParse(heightController.text) ?? 0;
        final totalInches = cm / 2.54;

        final feet = (totalInches / 12).floor();
        final inches = totalInches % 12;

        heightController.text = "${feet}'${inches.toStringAsFixed(1)}";
      }
    }

    // Weight conversion logic
    if (weightController.text.isNotEmpty) {
      if (isMetric) {
        // Convert from Pounds (lbs) to Kilograms (kg)
        final lbs = double.tryParse(weightController.text) ?? 0;
        final kg = lbs * 0.453592;
        weightController.text = kg.toStringAsFixed(1);
      } else {
        // Convert from Kilograms (kg) to Pounds (lbs)
        final kg = double.tryParse(weightController.text) ?? 0;
        final lbs = kg * 2.20462;
        weightController.text = lbs.toStringAsFixed(1);
      }
    }

    // Goal Weight conversion logic
    if (goalWeightController.text.isNotEmpty) {
      if (isMetric) {
        // Convert from Pounds (lbs) to Kilograms (kg)
        final lbs = double.tryParse(goalWeightController.text) ?? 0;
        final kg = lbs * 0.453592;
        goalWeightController.text = kg.toStringAsFixed(1);
      } else {
        // Convert from Kilograms (kg) to Pounds (lbs)
        final kg = double.tryParse(goalWeightController.text) ?? 0;
        final lbs = kg * 2.20462;
        goalWeightController.text = lbs.toStringAsFixed(1);
      }
    }
  }

  // Show goal weight suggestions based on current weight and goal
  void _showGoalWeightSuggestions() {
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

    if (_goal == 'Lose Weight' || _goal == 'Mild Lose Weight') {
      suggestions = [
        {'label': 'Mild Loss (-5%)', 'value': currentWeight * 0.95},
        {'label': 'Moderate Loss (-10%)', 'value': currentWeight * 0.90},
        {'label': 'Significant Loss (-15%)', 'value': currentWeight * 0.85},
      ];
    } else if (_goal == 'Gain Weight' || _goal == 'Mild Gain Weight') {
      suggestions = [
        {'label': 'Mild Gain (+5%)', 'value': currentWeight * 1.05},
        {'label': 'Moderate Gain (+10%)', 'value': currentWeight * 1.10},
        {'label': 'Significant Gain (+15%)', 'value': currentWeight * 1.15},
      ];
    } else {
      // For maintain weight, just use the current weight
      goalWeightController.text = currentWeight.toStringAsFixed(1);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1E1E1E),
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
                color: Colors.white,
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
                    style: TextStyle(color: Colors.white),
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

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    goalWeightController.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _goalWeightFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      //linear percent indicator?
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF121212),
          title: SizedBox(
            width: double.infinity,
            child: LinearPercentIndicator(
              backgroundColor: Color(0xFFe8def8),
              progressColor: Color(0xFF65558F),
              percent: 0.48,
              barRadius: Radius.circular(5),
            ),
          )),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(25.0, 5.0, 25.0, 25.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //text
                      Text(
                        'Start your Nutrition Journey',
                        textAlign: TextAlign.left,
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'We need a few more details to get started on your fitness journey. Your height and weight will be used to calculate your personalized daily macro intake. Your goal weight will be used to help you visualize your progress.',
                        style: TextStyle(color: Colors.grey),
                      ),

                      SizedBox(
                        height: 20,
                      ),

                      Text(
                        'What is your height, weight, and your weight goal in using this application?',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(
                        height: 20,
                      ),

                      // -------------------------------------
                      // Toggle Buttons for Measurement System
                      // -------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ToggleButtons(
                            onPressed: (int index) {
                              _convertUnits(
                                  index); // Use the updated conversion function
                            },
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            selectedBorderColor: AppColors.secondaryColor,
                            borderColor: Colors
                                .white, // White border for unselected buttons
                            borderWidth: 1, // Border width
                            selectedColor: Colors.white,
                            fillColor: AppColors.primaryColor,
                            color: Colors
                                .white, // White text for unselected buttons
                            constraints: const BoxConstraints(
                              minHeight: 40.0,
                              minWidth: 80.0,
                            ),
                            isSelected: _selectedUnits,
                            children: units,
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 30,
                      ),

                      // ---------------------
                      // Height Input
                      // ---------------------
                      Text(
                        'Height',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(
                        height: 5,
                      ),

                      //height textbox
                      Row(
                        children: [
                          Expanded(
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (hasFocus) {
                                  setState(() {});
                                }
                              },
                              child: MyTextfield(
                                hintText: isMetric
                                    ? 'Height (50-300 cm)'
                                    : 'Height (e.g., 5\'11 or 20-120 in)',
                                obscureText: false,
                                controller: heightController,
                                suffixText: isMetric ? 'cm' : 'in',
                                keyboardType: isMetric
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true)
                                    : TextInputType.text,
                                focusNode: _heightFocusNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) {
                                  _weightFocusNode.requestFocus();
                                },
                                inputFormatters: [
                                  _HeightInputFormatter(isMetric: isMetric),
                                  LengthLimitingTextInputFormatter(6),
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
                                        return 'Use format: feet\'inches (e.g. 5\'11)';
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

                                    // Updated regex to be more permissive for validation
                                    final regex = RegExp(
                                        r"^(\d{1,2}\'\d{1,2}(\.\d{1,2})?|\d{1,3}(\.\d{1,2})?)$");
                                    if (!regex.hasMatch(value)) {
                                      return 'Use format: feet\'inches (e.g. 5\'11) or inches only';
                                    }

                                    if (totalInches < 20 || totalInches > 120) {
                                      return 'Height should be between 20-120 inches';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 25,
                      ),

                      // ---------------------
                      // Weight Input
                      // ---------------------
                      Text(
                        'Weight',
                        style: TextStyle(color: Colors.white),
                      ),

                      SizedBox(
                        height: 5,
                      ),

                      //weight textbox
                      Row(
                        children: [
                          Expanded(
                            child: MyTextfield(
                              hintText: isMetric
                                  ? 'Weight (20-300 kg)'
                                  : 'Weight (40-660 lbs)',
                              obscureText: false,
                              focusNode: _weightFocusNode,
                              suffixText: isMetric ? 'kg' : 'lb',
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                _goalWeightFocusNode.requestFocus();
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                                _MacroInputFormatter(),
                              ],
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              controller: weightController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your weight';
                                }
                                final weight = double.tryParse(value) ?? 0;
                                if (isMetric && (weight < 20 || weight > 300)) {
                                  return 'Weight should be around 20-300 kg';
                                } else if (!isMetric &&
                                    (weight < 40 || weight > 660)) {
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
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 30,
                      ),

                      // ---------------------
                      // Weight Goal Input
                      // ---------------------

                      Text(
                        'What is your goal weight?',
                        style: TextStyle(color: Colors.white),
                      ),

                      SizedBox(
                        height: 5,
                      ),

                      //weight goal text field with suggest button
                      Row(
                        children: [
                          Expanded(
                            flex: 7, // 70% width
                            child: MyTextfield(
                              hintText: isMetric
                                  ? 'Weight (20-300 kg)'
                                  : 'Weight (40-660 lbs)',
                              obscureText: false,
                              suffixText: isMetric ? 'kg' : 'lb',
                              controller: goalWeightController,
                              focusNode: _goalWeightFocusNode,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                _goalWeightFocusNode.unfocus();
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                                _MacroInputFormatter(),
                              ],
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your desired weight';
                                }

                                // Validate the weight input based on the measurement system
                                final weight = double.tryParse(value) ?? 0;
                                if (isMetric && (weight < 20 || weight > 300)) {
                                  return 'Weight should be around 20-300 kg';
                                } else if (!isMetric &&
                                    (weight < 40 || weight > 660)) {
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

                                // Validate the weight input based on the goal
                                if (weightController.text.isNotEmpty) {
                                  final goalWeight =
                                      double.tryParse(value) ?? 0;
                                  final currentWeight =
                                      double.tryParse(weightController.text) ??
                                          0;

                                  if (_goal == 'Maintain Weight' &&
                                      goalWeight != currentWeight) {
                                    return 'Goal weight should be equal to the current weight for maintenance';
                                  } else if ((_goal == 'Lose Weight' ||
                                          _goal == 'Mild Lose Weight') &&
                                      goalWeight >= currentWeight) {
                                    return 'Goal weight should be less than current weight for weight loss';
                                  } else if ((_goal == 'Gain Weight' ||
                                          _goal == 'Mild Gain Weight') &&
                                      goalWeight <= currentWeight) {
                                    return 'Goal weight should be more than current weight for weight gain';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 3, // 30% width
                            child: ElevatedButton(
                              onPressed: _showGoalWeightSuggestions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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

                      SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ),
              //lower buttons back and continue button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    //back button with gesture detectore
                    CustomTextButton(
                        title: 'Back',
                        onTap: () {
                          context.push('/preference3');
                        },
                        size: 16),

                    SizedBox(width: 50),

                    //continue button
                    Expanded(
                      child: MyButtons(
                        text: 'Next',
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            await saveUserGoal();
                            context.push('/preference5');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeightInputFormatter extends TextInputFormatter {
  final bool isMetric;

  _HeightInputFormatter({required this.isMetric});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    if (isMetric) {
      // Allow only numbers and one decimal point for metric
      if (RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text)) {
        return newValue;
      }
    } else {
      // Allow numbers, one apostrophe, and one decimal point for imperial
      final apostropheCount = '\''.allMatches(newValue.text).length;
      final decimalCount = '.'.allMatches(newValue.text).length;

      if (apostropheCount <= 1 &&
          decimalCount <= 1 &&
          RegExp(r"^[\d\'.]*$").hasMatch(newValue.text)) {
        return newValue;
      }
    }

    return oldValue;
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
