import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const List<Widget> units = <Widget>[
  Text('US'),
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

  //saving user height, weight and goalweight
  //saving username and fullname
  Future<void> saveUserGoal() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final weight = double.tryParse(weightController.text);
      final height = double.tryParse(heightController.text);
      final goalWeight = double.tryParse(goalWeightController.text);
      final today = DateTime.now();

      // save current weight to history
      await FirebaseFirestore.instance
          .collection('weight_history')
          .doc('${user.uid}_${DateFormat('yyyy-MM-dd').format(today)}')
          .set({
        'userId': user.uid,
        'weight': weight,
        'date': Timestamp.now(),
      }, SetOptions(merge: true));

      // update user profile
      await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
        'height': height,
        'weight': weight,
        'goalWeight': goalWeight,
        'measurementSystem': isMetric ? 'Metric' : 'US',
      }, SetOptions(merge: true));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchGoalData();

    // listener to sync values with the current weight
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

  Future<void> _fetchGoalData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.email)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // Retrieve user data
        _goal = data['goal'] ?? 'Maintain Weight';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      }
      debugPrint('Error fetching user data: $e');
    }
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
                        'Welcome to TrackTasty! We’re excited to help you on your nutrition journey. To get started, we need a little information about you.',
                        style: TextStyle(color: Colors.grey),
                      ),

                      SizedBox(
                        height: 20,
                      ),

                      Text(
                        'Next, what is your height, weight, and your weight goal in using this application?',
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
                                    : 'Height (20-120 in)',
                                obscureText: false,
                                controller: heightController,
                                suffixText: isMetric ? 'cm' : 'in',
                                keyboardType: _isMetric
                                    ? TextInputType.numberWithOptions(
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
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your height';
                                  }

                                  if (isMetric) {
                                    // Metric validation (unchanged)
                                    final height = double.tryParse(value) ?? 0;
                                    if (height < 50 || height > 300) {
                                      return 'Height should be between 50-300 cm';
                                    }
                                  } else {
                                    // feet'inches support
                                    double totalInches;

                                    if (value.contains("'")) {
                                      // Handle feet'inches format (e.g. 5'3, 5'11.5)
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
                                      // Handle plain inches
                                      totalInches = double.tryParse(value) ?? 0;
                                    }

                                    // Update the controller with the computed inches (if feet'inches format was used)
                                    if (value.contains("'")) {
                                      final formattedValue =
                                          totalInches.toStringAsFixed(
                                              totalInches % 1 == 0 ? 0 : 1);
                                      heightController.text = formattedValue;
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
                            ],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please your desired weight';
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
                              if (goalWeightController.text.isNotEmpty &&
                                  weightController.text.isNotEmpty) {
                                final goalWeight =
                                    double.parse(goalWeightController.text);
                                final currentWeight =
                                    double.parse(weightController.text);
                                if (_goal == 'Maintain Weight' &&
                                    goalWeight != currentWeight) {
                                  return 'Goal weight should be equal to the current weight';
                                } else if (_goal == 'Lose Weight' &&
                                    goalWeight >= currentWeight) {
                                  return 'Goal weight should be less than current weight';
                                } else if (_goal == 'Gain Weight' &&
                                    goalWeight <= currentWeight) {
                                  return 'Goal weight should be more than current weight';
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
                          await saveUserGoal();
                          if (_formKey.currentState!.validate()) {
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
