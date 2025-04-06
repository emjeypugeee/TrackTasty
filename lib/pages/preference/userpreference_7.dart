import 'package:fitness/components/my_buttons.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class Userpreference7 extends StatefulWidget {
  const Userpreference7({super.key});

  @override
  State<Userpreference7> createState() => _Userpreference7();
}

class _Userpreference7 extends State<Userpreference7> {
  void goToUserpreference6(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference6Page');
  }

  void goToMainScreen(BuildContext context) {
    Navigator.pushNamed(context, '/MainScreenPage');
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
            percent: 0,
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
              'Welcome to TrackTasty! + nickname',
              style: TextStyle(color: Colors.grey),
            ),

            SizedBox(
              height: 20,
            ),

            Text(
              'First, how would you want us to address you?',
              style: TextStyle(
                color: Colors.white,
              ),
            ),

            SizedBox(
              height: 20,
            ),

            Text(
              'Full Name',
              style: TextStyle(color: Colors.white),
            ),

            SizedBox(height: 5),

            SizedBox(
              height: 20,
            ),

            Text(
              'Username',
              style: TextStyle(color: Colors.white),
            ),

            SizedBox(
              height: 5,
            ),

            SizedBox(
              height: 20,
            ),

            SizedBox(
              height: 40,
            ),

            // lower buttons back and continue
            Row(
              children: [
                //back button w/ gesture detector
                GestureDetector(
                  onTap: () {
                    goToUserpreference6(context);
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
                      goToMainScreen(context);
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
