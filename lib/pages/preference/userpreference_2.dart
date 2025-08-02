import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/selectable_Activity_Button.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Userpreference2 extends StatefulWidget {
  const Userpreference2({super.key});

  @override
  State<Userpreference2> createState() => _Userpreference2();
}

class _Userpreference2 extends State<Userpreference2> {
  int selectedIndex = -1; // Track selected button (-1 means no selection)

  //fetch process
  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchUserActivityLevel() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.email)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          selectedIndex =
              (doc.data() as Map<String, dynamic>)["selectedActivityLevel"] ??
                  -1;
        });
      }
    }
  }

  //selectable acitvity button values
  final List<Map<String, String>> activityLevels = [
    {'title': 'Sedentary', 'subtitle': '(little or no exercise)'},
    {'title': 'Lightly active', 'subtitle': '(exercise 1-3 days/week)'},
    {
      'title': 'Moderately active',
      'subtitle': '(moderate exercise 4-5 days/week)'
    },
    {'title': 'Very active', 'subtitle': '(intense exercise 6-7 days/week)'},
    {
      'title': 'Extra active',
      'subtitle': '(very intense exercise, or physical job)'
    },
  ];

  //saving activity levels thru firebase
  Future<void> saveUserActivityLevel() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null || selectedIndex == -1) return;

      await FirebaseFirestore.instance.collection("Users").doc(email).set(
        {"selectedActivityLevel": activityLevels[selectedIndex]['title']},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving activity level: $e');
      // Optionally show error to user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: SizedBox(
          width: double.infinity,
          child: LinearPercentIndicator(
            backgroundColor: AppColors.indicatorBg,
            progressColor: AppColors.indicatorProgress,
            percent: 0.3,
            barRadius: Radius.circular(5),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start your Nutrition Journey',
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Welcome to TrackTasty! We\'re excited to help you on your nutrition journey. To get started, we need a little information about you.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Next, how would you describe your activity level usually?',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 30),

                    // ------------------------
                    // Activity Level Selection
                    // ------------------------
                    Column(
                      children: List.generate(activityLevels.length, (index) {
                        return Selectableactivitybutton(
                          title: activityLevels[index]['title']!,
                          subtitle: activityLevels[index]['subtitle'],
                          isSelected: selectedIndex == index,
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 20), // Minimal bottom space
                  ],
                ),
              ),
            ),
            // Sticky Bottom Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  CustomTextButton(
                    title: 'Back',
                    onTap: () {
                      context.push('/preference1');
                    },
                    size: 16,
                  ),
                  SizedBox(width: 50),
                  // Next button (expanded to fill remaining space)
                  Expanded(
                    child: MyButtons(
                      text: 'Next',
                      onTap: () async {
                        if (selectedIndex == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Please select your activity level'),
                            backgroundColor: AppColors.snackBarBgError,
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Saved!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.snackBarBgSaved,
                          ));
                          await saveUserActivityLevel();
                          context.push('/preference3');
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
    );
  }
}
