import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/selectable_Activity_Button.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
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
    fetchUserActivityLevel(); // Fetch saved activity level from Firebase
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
    {'title': 'Not very active', 'subtitle': '(little or no exercise)'},
    {'title': 'Lightly active', 'subtitle': '(light exercise 1-3 days/week)'},
    {
      'title': 'Moderately active',
      'subtitle': '(moderate exercise 3-5 days/week)'
    },
    {'title': 'Very active', 'subtitle': '(intense exercise 6-7 days/week)'},
  ];

  //saving activity levels thru firebase
  Future<void> saveUserActivityLevel() async {
  try {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || selectedIndex == -1) return;
    
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(email)
        .set(
          {"selectedActivityLevel": activityLevels[selectedIndex]['title']},
          SetOptions(merge: true),
        );
  } catch (e) {
    debugPrint('Error saving activity level: $e');
    // Optionally show error to user
  }
}

  // ----------------------------
  // Navigation Methods
  // ----------------------------
  void goToUserpreference1(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference1Page');
  }

  void goToUserpreference3(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference3Page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      //linear percent indicator?
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
              'Next, how would you describe your activity level usually?',
              style: TextStyle(
                color: Colors.white,
              ),
            ),

            SizedBox(
              height: 30,
            ),

            //selectable acitivty buttons
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
                    });
              }),
            ),
            SizedBox(
              height: 90,
            ),

            // lower buttons back and continue
            Row(
              children: [
                //back button w/ gesture detector
                GestureDetector(
                  onTap: () {
                    goToUserpreference1(context);
                  },
                  child: const Text(
                    'Back',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFE99797)), // Adjust style as needed
                  ),
                ),

                SizedBox(width: 50),

                //continue button
                Expanded(
                  child: MyButtons(
                    text: 'Next',
                    onTap: () async {
                      saveUserActivityLevel();
                      if (selectedIndex == -1) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Please select your activity level'),
                          backgroundColor: Colors.red,
                        ));
                      } else {
                        await saveUserActivityLevel();
                        goToUserpreference3(context);
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
