import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/selectable_Activity_Button.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditFoodPreferencePage extends StatefulWidget {
  const EditFoodPreferencePage({super.key});

  @override
  State<EditFoodPreferencePage> createState() => _EditFoodPreferencePageState();
}

class _EditFoodPreferencePageState extends State<EditFoodPreferencePage> {
  int _currentTabIndex = 0; // 0 for diet, 1 for allergies
  int selectedDietIndex = -1;
  Map<String, bool> selectedAllergies = {};

  // Dietary preferences
  final List<Map<String, String>> dietaryPreference = [
    {'title': 'Vegetarian', 'subtitle': 'No meat, includes dairy & eggs'},
    {'title': 'Vegan', 'subtitle': 'No animal products whatsoever'},
    {'title': 'Pescatarian', 'subtitle': 'Vegetarian + fish & seafood'},
    {'title': 'Omnivore', 'subtitle': 'All food groups included'}
  ];

  // Allergies list
  final List<String> allergies = [
    "Celery",
    "Crustacean",
    "Dairy",
    "Egg",
    "Fish",
    "Gluten",
    "Lupine",
    "Mustard",
    "Peanut",
    "Sesame",
    "Shellfish",
    "Soy",
    "Tree-Nut",
    "Wheat",
  ];

  // User data
  String? userDietaryPreference;
  List<dynamic> userAllergies = [];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    // Initialize allergies map
    for (var allergy in allergies) {
      selectedAllergies[allergy] = false;
    }
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.email)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          // Load dietary preference
          userDietaryPreference = data['dietaryPreference']?.toString();
          if (userDietaryPreference != null) {
            selectedDietIndex = dietaryPreference
                .indexWhere((diet) => diet['title'] == userDietaryPreference);
          }

          // Load allergies
          userAllergies =
              data['allergies'] is List ? List.from(data['allergies']) : [];
          for (var allergy in allergies) {
            selectedAllergies[allergy] = userAllergies.contains(allergy);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  Future<void> _saveUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get selected diet
      final String? selectedDiet = selectedDietIndex != -1
          ? dietaryPreference[selectedDietIndex]['title']
          : null;

      // Get selected allergies
      final selectedAllergyList = selectedAllergies.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
        'dietaryPreference': selectedDiet,
        'allergies': selectedAllergyList,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food preferences updated successfully!'),
            backgroundColor: AppColors.snackBarBgSaved,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(); // Go back to previous page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppColors.snackBarBgError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Edit Food Preferences',
            style: TextStyle(color: AppColors.primaryText)),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryText,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab selection
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(0, 'Dietary Preference'),
                  ),
                  Expanded(
                    child: _buildTabButton(1, 'Allergies'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Content based on selected tab
            Expanded(
              child: _currentTabIndex == 0
                  ? _buildDietaryPreferenceTab()
                  : _buildAllergiesTab(),
            ),

            SizedBox(height: 20),

            // Save button
            MyButtons(
              text: 'Save Changes',
              onTap: _saveUserPreferences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDietaryPreferenceTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your dietary preference:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'This helps us provide better meal recommendations and nutritional guidance.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          SizedBox(height: 20),
          Column(
            children: List.generate(dietaryPreference.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Selectableactivitybutton(
                  title: dietaryPreference[index]['title']!,
                  subtitle: dietaryPreference[index]['subtitle'],
                  isSelected: selectedDietIndex == index,
                  onTap: () {
                    setState(() {
                      selectedDietIndex = index;
                    });
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your allergies:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'This helps us avoid recommending foods that may cause allergic reactions.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          SizedBox(height: 20),
          Column(
            children: allergies.map((allergy) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20.0),
                  clipBehavior: Clip.antiAlias,
                  child: CheckboxListTile(
                    title: Text(allergy, style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 20.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(
                        color: selectedAllergies[allergy] ?? false
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    value: selectedAllergies[allergy] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        selectedAllergies[allergy] = value!;
                      });
                    },
                    activeColor: AppColors.primaryColor,
                    checkColor: Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
