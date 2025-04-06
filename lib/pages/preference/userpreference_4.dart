import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Userpreference4 extends StatefulWidget {
  const Userpreference4({super.key});

  @override
  State<Userpreference4> createState() => _Userpreference4();
}

class _Userpreference4 extends State<Userpreference4> {
  //to track the state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  //Height, Weight and goal weight
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController goalWeightController = TextEditingController();

  //saving user height, weight and goalweight
  //saving username and fullname
  Future<void> saveUserGoal() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
        'height': heightController.text,
        'weight': weightController.text,
        'goalWeight': goalWeightController.text,
      }, SetOptions(merge: true));
    }
  }

  //method to move to userpreference2 page (back button)
  void goToUserpreference3(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference3Page');
  }

  //method to move to userpreference4 page (continue button)
  void goToUserpreference5(BuildContext context) {
    Navigator.pushNamed(context, '/Userpreference5Page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      //linear percent indicator?
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF121212),
          title: SizedBox(
            width: double.infinity,
            child: LinearPercentIndicator(
              backgroundColor: Color(0xFFe8def8),
              progressColor: Color(0xFF65558F),
              percent: 0.7,
              barRadius: Radius.circular(5),
            ),
          )),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
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
                'Next, what is your goal in using this application?',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              SizedBox(
                height: 20,
              ),

              SizedBox(
                height: 30,
              ),

              Text(
                'Height',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              SizedBox(
                height: 5,
              ),

              //height textbox
              Row(
                children: [
                  Expanded(
                    child: MyTextfield(
                      hintText: 'Value',
                      obscureText: false,
                      suffixText: 'cm',
                      controller: heightController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your height';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 25,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFe99797),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(15),
                    child: Center(
                      child: Text('   cm   '),
                    ),
                  )
                ],
              ),

              SizedBox(
                height: 25,
              ),

              Text(
                'Weight',
                style: TextStyle(color: Colors.white),
              ),

              SizedBox(
                height: 5,
              ),

              //weight textbox
              Row(
                children: [
                  Expanded(
                    child: MyTextfield(
                      hintText: 'Value',
                      obscureText: false,
                      suffixText: 'kg',
                      controller: weightController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your weight';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 25,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFe99797),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(15),
                    child: Center(
                      child: Text('   kg   '),
                    ),
                  )
                ],
              ),

              SizedBox(
                height: 30,
              ),

              Text(
                'What is your goal weight?',
                style: TextStyle(color: Colors.white),
              ),

              SizedBox(
                height: 5,
              ),

              //weight goal text field
              Row(
                children: [
                  Expanded(
                      child: MyTextfield(
                    hintText: 'Value',
                    obscureText: false,
                    controller: goalWeightController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please your desired weight';
                      }
                      return null;
                    },
                  )),
                  SizedBox(
                    width: 30,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFe99797),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(15),
                    child: Center(
                      child: Text('   kg   '),
                    ),
                  )
                ],
              ),

              SizedBox(
                height: 40,
              ),
              //lower buttons back and continue button
              Row(
                children: [
                  //back button with gesture detectore
                  GestureDetector(
                    onTap: () {
                      goToUserpreference3(context);
                    },
                    child: const Text(
                      'Back',
                      style: TextStyle(fontSize: 16, color: Color(0xFFE99797)),
                    ),
                  ),

                  SizedBox(width: 50),

                  //continue button
                  Expanded(
                    child: MyButtons(
                      text: 'Next',
                      onTap: () async {
                        await saveUserGoal();
                        if (_formKey.currentState!.validate()) {
                          goToUserpreference5(context);
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
    );
  }
}
