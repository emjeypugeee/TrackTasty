import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class Userpreference6 extends StatefulWidget {
  const Userpreference6({super.key});

  @override
  State<Userpreference6> createState() => _Userpreference6();
}

class _Userpreference6 extends State<Userpreference6> {
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

  Map<String, bool> selectedAllergies = {};

//saving user allergies
  Future<void> _saveUserAllergies() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final selected = selectedAllergies.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
        'allergies': selected,
        'preferencesCompleted': true, // Mark as fully completed
        'lastPreferenceStep': 6, // Indicate this is the final step
      }, SetOptions(merge: true));

      debugPrint('All preferences completed and saved');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving allergies: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    for (var allergy in allergies) {
      selectedAllergies[allergy] = false;
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
          title: LinearPercentIndicator(
            backgroundColor: Color(0xFFe8def8),
            progressColor: Color(0xFF65558F),
            percent: 0.8,
            barRadius: Radius.circular(5),
          )),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
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
              'Lastly, what are the allergies you have that we should know about? ',
              style: TextStyle(
                color: Colors.white,
              ),
            ),

            SizedBox(
              height: 20,
            ),
            //checkboxes
            Expanded(
                child: ListView(
              children: allergies.map((allergy) {
                return CheckboxListTile(
                  title: Text(allergy, style: TextStyle(color: Colors.white)),
                  value: selectedAllergies[allergy] ??
                      false, // Prevents null values
                  onChanged: (bool? value) {
                    setState(() {
                      selectedAllergies[allergy] = value!;
                    });
                  },
                  activeColor: Colors.purpleAccent,
                  checkColor: Colors.black,
                );
              }).toList(),
            )),

            SizedBox(
              height: 20,
            ),
            // lower buttons back and continue
            Row(
              children: [
                //back button w/ gesture detector
                CustomTextButton(
                    title: 'Back',
                    onTap: () {
                      context.push('/preference5');
                    },
                    size: 16),

                SizedBox(width: 50),

                //continue button
                Expanded(
                  child: MyButtons(
                    text: 'Next',
                    onTap: () async {
                      await _saveUserAllergies();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Saved!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.snackBarBgSaved,
                        ));
                        context.go('/home');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
