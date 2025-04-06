import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/selectable_Activity_Button.dart';
import 'package:flutter/material.dart';
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
  final List<Map<String, String>> activityLevels = [
    {'title': '+ Vegetarian'},
    {'title': '+ Vegan'},
    {'title': '+ Pescatarian'},
    {'title': '+ Omnivore'}
  ];

  void goToUserpreference4(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference4Page');
  }

  void goToUserpreference6(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference6Page');
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
              height: 100,
            ),

            // lower buttons back and continue
            Row(
              children: [
                //back button w/ gesture detector
                GestureDetector(
                  onTap: () {
                    goToUserpreference4(context);
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
                    onTap: () {
                      goToUserpreference6(context);
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
