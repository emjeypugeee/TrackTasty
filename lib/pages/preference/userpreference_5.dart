import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/selectable_Activity_Button.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class Userpreference5 extends StatefulWidget {
  const Userpreference5({super.key});

  @override
  State<Userpreference5> createState() => _Userpreference5();
}

class _Userpreference5 extends State<Userpreference5> {
  //means no selection
  int selectedIndex = -1;

  //selectable button values
  final List<Map<String, String>> dietaryPreference = [
    {'title': 'Vegetarian'},
    {'title': 'Vegan'},
    {'title': 'Pescatarian'},
    {'title': 'Omnivore'}
  ];

  //saving user dietary preference
  Future<void> saveUserDietaryPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
        'dietaryPreference': dietaryPreference[selectedIndex]['title'],
      }, SetOptions(merge: true));
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
                      'Thanks! Now let'
                      's talk about on what is your dietary preferences.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: 100,
                    ),

                    Column(
                      children:
                          List.generate(dietaryPreference.length, (index) {
                        return Selectableactivitybutton(
                            title: dietaryPreference[index]['title']!,
                            subtitle: dietaryPreference[index]['subtitle'],
                            isSelected: selectedIndex == index,
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                            });
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // lower buttons back and continue
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  //back button w/ gesture detector
                  CustomTextButton(
                      title: 'Back',
                      onTap: () {
                        context.push('/preference4');
                      },
                      size: 16),

                  SizedBox(width: 50),

                  //continue button
                  Expanded(
                    child: MyButtons(
                      text: 'Next',
                      onTap: () async {
                        if (selectedIndex == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('Please select your dietary preference'),
                            backgroundColor: AppColors.snackBarBgError,
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Saved!'),
                            backgroundColor: AppColors.snackBarBgSaved,
                          ));
                          await saveUserDietaryPreference();
                          context.push('/preference6');
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
