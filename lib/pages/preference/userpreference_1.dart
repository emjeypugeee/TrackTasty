import 'dart:io';
import 'package:fitness/model/user_data_models.dart';
import 'package:fitness/provider/registration_data_provider.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:fitness/widgets/components/gender_button.dart';
import 'package:provider/provider.dart';

class Userpreference1 extends StatefulWidget {
  const Userpreference1({super.key});

  @override
  State<Userpreference1> createState() => _Userpreference1();
}

enum Gender { male, female }

class _Userpreference1 extends State<Userpreference1> {
  Gender? selectedGender;
  bool _isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _ageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    await provider.loadFromPreferences(); // Load data from SharedPreferences

    // Pre-fill data if available
    usernameController.text = provider.userData.username ?? '';
    ageController.text = provider.userData.age?.toString() ?? '';
    selectedGender = provider.userData.gender == 'male'
        ? Gender.male
        : provider.userData.gender == 'female'
            ? Gender.female
            : null;

    setState(() {}); // Update the UI after loading data
  }

  Future<bool> saveNickname() async {
    if (_formKey.currentState!.validate() && selectedGender != null) {
      final provider =
          Provider.of<RegistrationDataProvider>(context, listen: false);

      // Update the provider with new data
      provider.updateBasicInfo(
        username: usernameController.text,
        age: int.tryParse(ageController.text),
        gender: selectedGender?.name,
      );

      return true;
    }
    return false;
  }

  void _saveDataOnBack() async {
    if (usernameController.text.isNotEmpty ||
        ageController.text.isNotEmpty ||
        selectedGender != null) {
      final provider =
          Provider.of<RegistrationDataProvider>(context, listen: false);

      if (usernameController.text.isNotEmpty) {
        provider.updateBasicInfo(username: usernameController.text);
      }

      if (ageController.text.isNotEmpty) {
        final age = int.tryParse(ageController.text);
        if (age != null) {
          provider.updateBasicInfo(age: age);
        }
      }

      if (selectedGender != null) {
        provider.updateBasicInfo(gender: selectedGender!.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: LinearPercentIndicator(
          backgroundColor: AppColors.indicatorBg,
          progressColor: AppColors.indicatorProgress,
          percent: 0,
          barRadius: const Radius.circular(5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start your Nutrition Journey',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 22),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Welcome to TrackTasty! We’re excited to help you on your nutrition journey. To get started, we need a little information about you.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'What should we call you and how old are you?',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 20),

                      // ---------------------
                      // Username Input
                      // ---------------------
                      const Text(
                        'Username',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 5),
                      MyTextfield(
                        hintText: 'Enter your username',
                        obscureText: false,
                        controller: usernameController,
                        focusNode: _usernameFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _ageFocusNode.requestFocus();
                        },
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z ]')), // Letters + spaces only
                          LengthLimitingTextInputFormatter(30), // Max 30 chars
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ---------------------
                      // Age Input
                      // ---------------------
                      const Text(
                        'Age',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 5),
                      MyTextfield(
                        hintText: 'Enter your age',
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        focusNode: _ageFocusNode,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          _ageFocusNode.unfocus();
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: ageController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your age';
                          }
                          final age = int.tryParse(value);
                          if (age == null) {
                            return 'Please enter a valid number';
                          }
                          if (age < 14 || age > 80) {
                            return 'Please enter a valid age (14-80)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ---------------------
                      // Gender Selection
                      // ---------------------
                      Text(
                        'Please select your gender: \n',
                        style: TextStyle(color: Colors.white),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GenderIcon(
                              isSelected: selectedGender == Gender.male,
                              iconData: Icons.male,
                              onTap: () =>
                                  setState(() => selectedGender = Gender.male),
                              selectedColor: Colors.blue[800]!),
                          SizedBox(
                            width: 40,
                          ),
                          GenderIcon(
                              isSelected: selectedGender == Gender.female,
                              iconData: Icons.female,
                              onTap: () => setState(
                                  () => selectedGender = Gender.female),
                              selectedColor: Colors.pink[800]!)
                        ],
                      ),

                      SizedBox(
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ),

              // Sticky bottom buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    CustomTextButton(
                      title: 'Back',
                      onTap: () async {
                        final provider = Provider.of<RegistrationDataProvider>(
                            context,
                            listen: false);

                        // Save data before navigating back
                        if (usernameController.text.isNotEmpty) {
                          provider.updateBasicInfo(
                              username: usernameController.text);
                        }

                        if (ageController.text.isNotEmpty) {
                          final age = int.tryParse(ageController.text);
                          if (age != null) {
                            provider.updateBasicInfo(age: age);
                          }
                        }

                        if (selectedGender != null) {
                          provider.updateBasicInfo(
                              gender: selectedGender!.name);
                        }

                        context.push('/startup');
                      },
                      size: 16,
                    ),
                    const SizedBox(width: 50),
                    Expanded(
                      child: MyButtons(
                        text: _isLoading ? 'Loading...' : 'Next',
                        onTap: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isLoading = true);

                                  if (selectedGender == null) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text('Please select your gender'),
                                      backgroundColor:
                                          AppColors.snackBarBgError,
                                    ));
                                    setState(() => _isLoading = false);
                                    return;
                                  }

                                  bool success = await saveNickname();
                                  if (success && mounted) {
                                    context.push('/preference2');
                                  }
                                  setState(() => _isLoading = false);
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
