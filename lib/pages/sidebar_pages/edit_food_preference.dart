import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/selectable_Activity_Button.dart';
import 'package:fitness/theme/app_color.dart';
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
    {'title': 'Omnivore', 'subtitle': 'All food groups included'},
    {'title': 'Vegetarian', 'subtitle': 'No meat, includes dairy and eggs'},
    {'title': 'Vegan', 'subtitle': 'No animal products whatsoever'},
    {
      'title': 'Pescatarian',
      'subtitle': 'No meat, but includes fish and seafood'
    },
    {'title': 'Keto', 'subtitle': 'Low carbs, high fat'},
    {'title': 'Paleo', 'subtitle': 'Focuses on whole, unprocessed foods'},
  ];

  // Allergies list
  final List<Map<String, String>> allergies = [
    {
      'title': 'Crustacean Shellfish',
      'subtitle': 'e.g., Shrimp, crab, lobster, crawfish'
    },
    {'title': 'Dairy (Milk)', 'subtitle': 'e.g., Milk, cheese, butter, yogurt'},
    {'title': 'Egg', 'subtitle': 'e.g., Eggs, mayonnaise, custards'},
    {'title': 'Fish', 'subtitle': 'e.g., Tuna, salmon, cod, trout'},
    {'title': 'Peanut', 'subtitle': 'e.g., Peanuts, peanut butter, peanut oil'},
    {'title': 'Sesame', 'subtitle': 'e.g., Sesame seeds, tahini, sesame oil'},
    {'title': 'Soy', 'subtitle': 'e.g., Soybeans, edamame, tofu, soy sauce'},
    {
      'title': 'Tree Nuts',
      'subtitle': 'e.g., Almonds, walnuts, cashews, pecans'
    },
    {'title': 'Wheat', 'subtitle': 'e.g., Bread, pasta, flour, cereals'},
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
      selectedAllergies[allergy['title']!] = false;
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
            selectedAllergies[allergy['title']!] =
                userAllergies.contains(allergy);
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
            children: allergies.map((item) {
              final allergyTitle = item['title']!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  color: const Color.fromARGB(255, 32, 32, 32),
                  borderRadius: BorderRadius.circular(20.0),
                  clipBehavior: Clip.antiAlias,
                  child: CheckboxListTile(
                    title: Text(
                      allergyTitle,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      item['subtitle']!,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 20.0),
                    tileColor: selectedAllergies[allergyTitle] ?? false
                        ? AppColors.primaryColor
                            .withValues(alpha: 0.2) // Highlight color
                        : Colors.transparent,
                    value: selectedAllergies[allergyTitle] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        selectedAllergies[allergyTitle] = value!;
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
