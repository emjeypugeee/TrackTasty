import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  Future<void> _loadCurrentMeasurement() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('Users').doc(user.email).get();

    if (doc.exists) {
      setState(() {
        final measurementSystem = doc.data()?['measurementSystem'];
        debugPrint("User's measurement System: $measurementSystem");
        isMetric = measurementSystem == "Metric";
        isAdmin = doc.data()?['isAdmin'] ?? false;
      });
    }
  }

  // Editting username
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
                    final username = usernameController.text.trim();
                    // Basic validations
                    if (username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a username')),
                      );
                      return;
                    }
                    try {
                      final success = await userProvider.updateUsername(username);
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nickname updated successfully!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update nickname')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    TextEditingController editWeightController = TextEditingController();
    FocusNode editWeightNode = FocusNode();

    // Initialize with current weight if available
    if (userProvider.weight != null) {
      editWeightController.text = userProvider.weight!.toStringAsFixed(1);
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
                  color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 27),
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
                            style: TextStyle(color: AppColors.primaryText, fontSize: 20),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                      MyTextfield(
                        hintText: userProvider.measurementSystem == 'Metric'
                            ? 'Weight (20-300 kg)'
                            : 'Weight (40-660 lbs)',
                        obscureText: false,
                        focusNode: editWeightNode,
                        suffixText: userProvider.measurementSystem == 'Metric' ? 'kg' : 'lb',
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          editWeightNode.unfocus();
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        controller: editWeightController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value) ?? 0;

                          final isMetric = userProvider.measurementSystem == 'Metric';
                          if (isMetric && (weight < 20 || weight > 300)) {
                            return 'Weight should be around 20-300 kg';
                          } else if (!isMetric && (weight < 40 || weight > 660)) {
                            return 'Weight should be around 40-660 lbs';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CustomTextButton(
                              size: 20,
                              title: 'Cancel',
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: MyButtons(
                              text: 'Save',
                              onTap: () async {
                                if (formKey.currentState!.validate()) {
                                  final newWeight =
                                      double.tryParse(editWeightController.text) ?? 0.0;
                                  bool success = await userProvider.updateWeight(newWeight);

                                  if (context.mounted) {
                                    if (success) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Weight updated successfully!')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Failed to update weight. Please try again.')),
                                      );
                                    }
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
  }

  //
  // CHANGE GOAL WEIGHT DIALOG
  //
  void _showEditGoalSheet(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Controllers and variables for form fields
    TextEditingController weightController = TextEditingController();
    TextEditingController heightController = TextEditingController();
    TextEditingController ageController = TextEditingController();
    String? selectedGender;
    String? selectedActivityLevel;
    String? selectedGoal;

    // Initialize with current values from provider
    ageController.text = userProvider.age?.toString() ?? '';
    weightController.text = userProvider.weight?.toString() ?? '';
    heightController.text = userProvider.height?.toString() ?? '';
    selectedGender = userProvider.gender ?? 'male';
    selectedActivityLevel = userProvider.selectedActivityLevel ?? 'Sedentary';
    selectedGoal = userProvider.goal ?? 'Maintain Weight';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.containerBg,
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
                        color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),

                // Scrollable form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Age Field
                        Text(
                          'Age',
                          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                        ),
                        TextFormField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your age',
                            filled: true,
                            fillColor: AppColors.textFieldBg,
                          ),
                          style: TextStyle(color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 15),

                        // Weight Field
                        Text(
                          'Weight (${userProvider.measurementSystem == 'Metric' ? 'kg' : 'lbs'})',
                          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                        ),
                        TextFormField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your weight',
                            filled: true,
                            fillColor: AppColors.textFieldBg,
                          ),
                          style: TextStyle(color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 15),

                        // Height Field
                        Text(
                          'Height (${userProvider.measurementSystem == 'Metric' ? 'cm' : 'inches'})',
                          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                        ),
                        TextFormField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your height',
                            filled: true,
                            fillColor: AppColors.textFieldBg,
                          ),
                          style: TextStyle(color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 15),

                        // Gender Dropdown
                        Text(
                          'Gender',
                          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                        ),
                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          dropdownColor: const Color.fromARGB(255, 15, 15, 15),
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
                                    child: Text(gender == 'male' ? 'Male' : 'Female'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                        // Activity Level Dropdown
                        Text(
                          'Activity Level',
                          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                        ),
                        DropdownButtonFormField<String>(
                          value: selectedActivityLevel,
                          dropdownColor: const Color.fromARGB(255, 15, 15, 15),
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
                        ),
                        const SizedBox(height: 15),

                        // Goal Dropdown
                        Text(
                          'Goal',
                          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                        ),
                        DropdownButtonFormField<String>(
                          value: selectedGoal,
                          dropdownColor: const Color.fromARGB(255, 15, 15, 15),
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
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // Buttons at the bottom (outside the scrollable area)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: MyButtons(
                          text: 'Recalculate',
                          onTap: () async {
                            try {
                              final success = await userProvider.updateUserProfile(
                                age: int.tryParse(ageController.text) ?? userProvider.age ?? 0,
                                weight: double.tryParse(weightController.text) ??
                                    userProvider.weight ??
                                    0,
                                height: double.tryParse(heightController.text) ??
                                    userProvider.height ??
                                    0,
                                gender: selectedGender!,
                                activityLevel: selectedActivityLevel!,
                                goal: selectedGoal!,
                              );

                              if (success) {
                                // Close the bottom sheet first
                                Navigator.pop(context);

                                // Then navigate using go_router
                                context.push('/recalcmacros', extra: {
                                  'userData': {
                                    'age': int.tryParse(ageController.text),
                                    'weight': double.tryParse(weightController.text),
                                    'height': double.tryParse(heightController.text),
                                    'gender': selectedGender,
                                    'selectedActivityLevel': selectedActivityLevel,
                                    'goal': selectedGoal,
                                    'measurementSystem': userProvider.measurementSystem,
                                  },
                                  'selectedGoal': selectedGoal!,
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update profile')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }),
                    )
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

  //
  // LOGOUT DIALOG
  //
  void _showlogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomTextButton(
                  title: 'Back',
                  onTap: () {
                    Navigator.pop(context);
                  },
                  size: 20,
                ),
              ),
              Expanded(
                child: MyButtons(
                  text: 'Log out',
                  onTap: () {
                    context.read<UserProvider>().logout();
                    context.push('/login');
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
      isScrollControlled: true, // Allows the sheet to expand to needed height
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Takes only needed space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            const SizedBox(height: 16),
            // Header
            Center(
              child: Text(
                'About Us',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Divider(
              color: AppColors.primaryText.withOpacity(0.3),
              thickness: 1,
            ),
            const SizedBox(height: 20),

            // Mission Section
            Text(
              'OUR MISSION',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'To empower individuals to live healthier lives by making food tracking simple, smart, and supportive through innovative technology and a caring community.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),

            // Vision Section
            Text(
              'OUR VISION',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'To become the essential wellness companion that helps people build lasting healthy habits — one meal, one step, one goal at a time.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),

            // Closing statement
            Center(
              child: Text(
                'Join us on this journey to better health!',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
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

              Center(
                child: Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Divider(
                color: AppColors.primaryText.withValues(alpha: 0.3),
                thickness: 1,
              ),
              const SizedBox(height: 20),

              // 1. Acceptance of Terms
              Text(
                '1. ACCEPTANCE OF TERMS',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By accessing or using TrackTasty ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to all terms, please discontinue use immediately. Continued use constitutes acceptance of any modifications.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 2. Service Description
              Text(
                '2. SERVICE DESCRIPTION',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TrackTasty is a macro-nutrient tracking application designed to help beginners monitor food intake, calculate nutritional requirements, and support weight management goals. The App provides personalized macro calculations based on user-provided information including age, gender assigned at birth, weight, height, activity level, weight goals, dietary preferences, and allergies.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 3. User Responsibilities
              Text(
                '3. USER RESPONSIBILITIES',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• You must provide accurate and complete information for macro calculations\n• You agree to use the App only for lawful purposes\n• You must be at least 14 years old to use the App\n• You acknowledge that results may vary based on individual adherence',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 4. Medical Disclaimer
              Text(
                '4. MEDICAL DISCLAIMER',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TrackTasty provides nutritional information and tracking tools for informational purposes only. The App is not intended to diagnose, treat, cure, or prevent any disease or health condition. Always consult with a qualified healthcare professional before making significant changes to your diet or exercise routine. The macro calculations are estimates and should be used as guidelines rather than strict prescriptions.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 5. Data Collection and Privacy
              Text(
                '5. DATA COLLECTION AND PRIVACY',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We collect personal information including dietary preferences, and usage data to provide personalized services. Your data is stored securely and handled in accordance with our Privacy Policy. By using TrackTasty, you consent to the collection and processing of your data as described in our Privacy Policy.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 6. Intellectual Property
              Text(
                '6. INTELLECTUAL PROPERTY',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All content, features, and functionality of TrackTasty are owned by us and are protected by international copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, or create derivative works without explicit permission.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 7. Limitation of Liability
              Text(
                '7. LIMITATION OF LIABILITY',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TrackTasty and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the App. This includes but is not limited to errors in macro calculations, nutritional information, or any health-related outcomes.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 8. Modifications to Terms
              Text(
                '8. MODIFICATIONS TO TERMS',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We reserve the right to modify these Terms and Conditions at any time. Continued use of the App after changes constitutes acceptance of the modified terms. Users will be notified of significant changes through the App or via email.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 9. Termination
              Text(
                '9. TERMINATION',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We may terminate or suspend your access to TrackTasty immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users or the App\'s operation.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 10. Governing Law
              Text(
                '10. GOVERNING LAW',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction where TrackTasty is operated, without regard to its conflict of law provisions.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Acceptance Note
              Center(
                child: Text(
                  'By using TrackTasty, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
                    style: TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  onTap: () => _showEditUsernameDialog(context),
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Goals',
                    style: TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  onTap: () => _showEditGoalSheet(context), // This should call the updated function
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Food Preference',
                    style: TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    context.push('/editfoodpreference'); // Navigate to the new page
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Weight',
                    style: TextStyle(color: AppColors.primaryText, fontSize: 14),
                  ),
                  onTap: () => editWeightDialog(context),
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
                Navigator.pop(context); // Close the drawer
                context.push('/feedback'); // Navigate to feedback page
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: AppColors.drawerIcons),
              title: Text(
                'Settings',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
            ),
            ListTile(
              leading: Icon(Icons.people_rounded, color: AppColors.drawerIcons),
              title: Text(
                'About Us',
                style: TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              onTap: () => _showAboutUs(context),
            ),
            isAdmin
                ? ListTile(
                    leading: Icon(Icons.admin_panel_settings, color: AppColors.drawerIcons),
                    title: Text(
                      'Admin Page',
                      style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                    ),
                    onTap: () => context.push('/adminonly'),
                  )
                : const SizedBox.shrink(),
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

  void editWeightDialog(BuildContext context) => _showEditWeightDialog(context);
}
