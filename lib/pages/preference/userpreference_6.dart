import 'package:fitness/components/my_buttons.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    for (var allergy in allergies) {
      selectedAllergies[allergy] = false;
    }
  }

  void goToUserpreference5(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference5Page');
  }

  void goToUserpreference7(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference7Page');
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
                GestureDetector(
                  onTap: () {
                    goToUserpreference5(context);
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
                      goToUserpreference7(context);
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
