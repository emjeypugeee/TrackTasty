import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/pages/main_pages/home_page.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/main_screen_widgets/bottom_sheet_widgets/about_us_widget.dart';
import 'package:fitness/widgets/main_screen_widgets/bottom_sheet_widgets/faq_widget.dart';
import 'package:fitness/widgets/main_screen_widgets/bottom_sheet_widgets/terms_conditions_widget.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  // get user data
  bool isMetric = false;
  bool isAdmin = false;
  Future<void> signOutUser() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentMeasurement();
  }

  void refreshHomePage() {
    if (homePageKey.currentState != null) {
      homePageKey.currentState!.setState(() {});
    }
  }

  Future<void> _loadCurrentMeasurement() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();

    if (doc.exists) {
      setState(() {
        final measurementSystem = doc.data()?['measurementSystem'];
        debugPrint("User's measurement System: $measurementSystem");
        isMetric = measurementSystem == "Metric";
        isAdmin = doc.data()?['isAdmin'] ?? false;
      });
    }
  }

  // Editing username
  void _showEditUsernameDialog(BuildContext context) {
    TextEditingController usernameController = TextEditingController();
    final userProvider = context.read<UserProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.containerBg,
        title: Center(
          child: Text(
            'Change your nickname:',
            style: TextStyle(color: AppColors.primaryText),
          ),
        ),
        content: MyTextfield(
          hintText: 'Nickname:',
          obscureText: false,
          controller: usernameController,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomTextButton(
                  title: 'Back',
                  onTap: () => Navigator.pop(context),
                  size: 20,
                ),
              ),
              Expanded(
                child: MyButtons(
                  text: 'Save',
                  onTap: () async {
                    bool success = await userProvider
                        .updateUsername(usernameController.text);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Nickname updated successfully!')),
                      );
                      refreshHomePage();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //
  // EDIT WEIGHT DIALOG
  //
  void _showEditWeightDialog(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final formKey = GlobalKey<FormState>();

    TextEditingController editWeightController = TextEditingController();
    FocusNode editWeightNode = FocusNode();

    final today = DateTime.now();

    Future<bool> saveUserPreferences(double weight) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(user.email)
            .set({
          'weight': weight,
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('weight_history')
            .doc('${user.uid}_${DateFormat('yyyy-MM-dd').format(today)}')
            .set({
          'userId': user.uid,
          'weight': weight,
          'date': Timestamp.now(),
        }, SetOptions(merge: true));
        return true;
      }
      return false;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.containerBg,
            title: Text(
              'Update Weight',
              style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 27),
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: screenWidth * 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Weight:',
                            style: TextStyle(
                                color: AppColors.primaryText, fontSize: 20),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                      MyTextfield(
                        hintText: isMetric
                            ? 'Weight (20-300 kg)'
                            : 'Weight (40-660 lbs)',
                        obscureText: false,
                        focusNode: editWeightNode,
                        suffixText: isMetric ? 'kg' : 'lb',
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          editWeightNode.unfocus();
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                          _MacroInputFormatter(),
                        ],
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        controller: editWeightController,
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
                      SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: MyButtons(
                              text: 'Save',
                              onTap: () async {
                                // validate the form
                                if (formKey.currentState!.validate()) {
                                  bool success = await saveUserPreferences(
                                      double.tryParse(
                                              editWeightController.text) ??
                                          0.0);
                                  if (success && context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Goals updated successfully!')),
                                    );
                                    refreshHomePage();
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // end of alertdialog
  }

  //
  // CHANGE GOAL WEIGHT DIALOG
  //
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
                                'Weight (${userData['measurementSystem'] == 'Metric' ? 'kg' : 'lbs'})',
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
                                  FilteringTextInputFormatter.digitsOnly,
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
                                style: TextStyle(color: AppColors.primaryText),
                              ),
                              const SizedBox(height: 15),

                              // Goal Weight Field
                              Text(
                                'Goal Weight (${userData['measurementSystem'] == 'Metric' ? 'kg' : 'lbs'})',
                                style: TextStyle(
                                    color: AppColors.primaryText, fontSize: 16),
                              ),
                              TextFormField(
                                controller: goalWeightController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter your goal weight',
                                  filled: true,
                                  fillColor: AppColors.textFieldBg,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                  _MacroInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your goal weight';
                                  }
                                  final goalWeight =
                                      double.tryParse(value) ?? 0;
                                  if (isMetric &&
                                      (goalWeight < 20 || goalWeight > 300)) {
                                    return 'Goal weight should be around 20-300 kg';
                                  } else if (!isMetric &&
                                      (goalWeight < 40 || goalWeight > 660)) {
                                    return 'Goal weight should be around 40-660 lbs';
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
                                style: TextStyle(color: AppColors.primaryText),
                              ),
                              const SizedBox(height: 15),

                              // Height Field
                              Text(
                                'Height (${userData['measurementSystem'] == 'Metric' ? 'cm' : 'inches'})',
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
                                      RegExp(r"[0-9\']")),
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
                                onChanged: (value) {
                                  setState(() {
                                    selectedGoal = value;
                                  });
                                },
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
                            onTap: () {
                              // Validate all form fields before proceeding
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context);

                                // Debug prints
                                debugPrint(
                                    "Age from controller: ${ageController.text}");
                                debugPrint(
                                    "Weight from controller: ${weightController.text}");
                                debugPrint(
                                    "Height from controller: ${heightController.text}");
                                debugPrint(
                                    "Goal Weight from controller: ${goalWeightController.text}");

                                // Create updated user data with the new values
                                Map<String, dynamic> updatedUserData =
                                    Map.from(userData);
                                updatedUserData['age'] =
                                    int.tryParse(ageController.text) ??
                                        userData['age'];
                                updatedUserData['weight'] =
                                    double.tryParse(weightController.text) ??
                                        userData['weight'];
                                updatedUserData['goalWeight'] = double.tryParse(
                                        goalWeightController.text) ??
                                    userData['goalWeight'];
                                updatedUserData['height'] =
                                    double.tryParse(heightController.text) ??
                                        userData['height'];
                                updatedUserData['gender'] = selectedGender;
                                updatedUserData['selectedActivityLevel'] =
                                    selectedActivityLevel;
                                updatedUserData['goal'] = selectedGoal;

                                // Navigate to the recalculate macros page with all parameters
                                context.push('/recalcmacros', extra: {
                                  'userData': updatedUserData,
                                  'selectedGoal': selectedGoal!,
                                });
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

  //
  // LOGOUT DIALOG
  //
  void _showlogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomTextButton(
                    title: 'Back',
                    onTap: () {
                      Navigator.pop(dialogContext);
                    },
                    size: 20),
              ),
              Expanded(
                child: MyButtons(
                  text: 'Log out',
                  onTap: () async {
                    // Clear chatbot conversation from SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    const String chatStorageKey = 'chatbot_conversation';
                    await prefs.remove(chatStorageKey);

                    // log out the user
                    dialogContext.read<UserProvider>().logout();
                    Navigator.pop(dialogContext);
                    context.go('/startup');
                  },
                ),
              ),
            ],
          )
        ],
        backgroundColor: AppColors.containerBg,
        title: Center(
          child: Text(
            'Log out?',
            style: TextStyle(color: AppColors.primaryText),
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  //
  // ABOUT US DIALOG
  //
  void _showAboutUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.containerBg,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => const AboutUsWidget(),
    );
  }

  //
  // T&C DIALOG
  //
  void _showTermsAndCondition(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.containerBg,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => const TermsConditionsWidget(),
    );
  }

  //
  // FAQs Section
  //
  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.containerBg,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => const FAQWidget(),
    );
  }

  //
  // SIDE BAR UI
  //
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.drawerBg,
        child: ListView(
          children: [
            DrawerHeader(
              child: Center(
                child: Image.asset('lib/images/TrackTastyLogo.png'),
              ),
            ),
            ExpansionTile(
              childrenPadding: EdgeInsets.only(left: 20),
              leading: Icon(
                Icons.person,
                color: AppColors.drawerIcons,
              ),
              title: Text(
                'User Profile',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              children: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Username',
                    style:
                        TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  onTap: () => _showEditUsernameDialog(context),
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Goals',
                    style:
                        TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  onTap: () => _showEditGoalSheet(context),
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Food Preference',
                    style:
                        TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                        '/editfoodpreference'); // Navigate to edit food pref page
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Weight',
                    style:
                        TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  onTap: () => _showEditWeightDialog(context),
                ),
              ],
            ),
            ListTile(
              leading: Icon(
                Icons.feed_outlined,
                color: AppColors.drawerIcons,
              ),
              title: Text(
                'Terms and Conditions',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              onTap: () => _showTermsAndCondition(context),
            ),
            ListTile(
              leading: Icon(Icons.feedback, color: AppColors.drawerIcons),
              title: Text(
                'Feedback',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/feedback'); // Navigate to feedback page
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications, color: AppColors.drawerIcons),
              title: Text(
                'Notification Settings',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(
                    '/notificationsettings'); // Navigate to notification settings
              },
            ),
            ListTile(
              leading: Icon(Icons.people_rounded, color: AppColors.drawerIcons),
              title: Text(
                'About Us',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              onTap: () => _showAboutUs(context),
            ),
            ListTile(
              leading: Icon(Icons.question_mark, color: AppColors.drawerIcons),
              title: Text(
                'FAQs',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              onTap: () => _showFAQ(context),
            ),
            SizedBox(height: 20),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Log Out',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              onTap: () => _showlogout(context),
            ),
          ],
        ),
      ),
    );
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
