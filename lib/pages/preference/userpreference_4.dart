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

  bool _isMetric = false;
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
    final height = double.tryParse(heightController.text);
    final weight = double.tryParse(weightController.text);
    final goalWeight = double.tryParse(goalWeightController.text);

    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);

    provider.updateBodyMetrics(
      height: height,
      weight: weight,
      goalWeight: goalWeight,
      isMetric: isMetric,
    );
  }

  void _convertUnits() {
    // Height conversion logic
    if (heightController.text.isNotEmpty) {
      if (!isMetric) {
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

    // Weight conversion logic (unchanged)
    if (weightController.text.isNotEmpty) {
      if (!isMetric) {
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
        padding: const EdgeInsets.all(25.0),
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
                              final hadFocus = _heightFocusNode.hasFocus;

                              // 1. Immediately update the state
                              setState(() {
                                for (int i = 0;
                                    i < _selectedUnits.length;
                                    i++) {
                                  _selectedUnits[i] = i == index;
                                }
                                _isMetric = _selectedUnits[1];
                                isMetric = _selectedUnits[1];

                                _convertUnits();
                              });

                              // 2. Force keyboard refresh if field was focused
                              if (hadFocus) {
                                // Unfocus and refocus with a small delay
                                _heightFocusNode.unfocus();

                                // Using a 50ms delay seems to be the sweet spot for reliability
                                Future.delayed(const Duration(milliseconds: 50),
                                    () {
                                  if (mounted) {
                                    _heightFocusNode.requestFocus();
                                  }
                                });
                              }

                              debugPrint(
                                  isMetric ? "Using Metric" : "Using US");
                            },
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            selectedBorderColor: AppColors.secondaryColor,
                            selectedColor: Colors.white,
                            fillColor: AppColors.primaryColor,
                            color: Colors.red[400],
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
                                    : 'Height (e.g., 5\'11" or 20-120 in)',
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
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r"[0-9\']")),
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
                                  : 'Height (40-660 lbs)',
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

                      //weight goal text field
                      Row(
                        children: [
                          Expanded(
                              child: MyTextfield(
                            hintText: isMetric
                                ? 'Weight (20-300 kg)'
                                : 'Height (40-660 lbs)',
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
                            ],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
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

                              // Validate the weight input based on the goal
                              if (weightController.text.isNotEmpty) {
                                final goalWeight = double.tryParse(value) ?? 0;
                                final currentWeight =
                                    double.tryParse(weightController.text) ?? 0;

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
                          )),

                          /*
                          OLD CODE FOR WEIGHT UNIT SELECTION
                          SizedBox(
                            width: 25,
                          ),
                          Container(
                            width: 70,
                            decoration: BoxDecoration(
                              color: Color(0xFFe99797),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.all(15),
                            child: Center(
                              child: Text(isMetric ? 'kg' : 'lb'),
                            ),
                          )
                          */
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
