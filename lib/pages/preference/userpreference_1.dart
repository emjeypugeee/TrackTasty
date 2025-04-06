import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class Userpreference1 extends StatefulWidget {
  const Userpreference1({super.key});

  @override
  State<Userpreference1> createState() => _Userpreference1();
}

class _Userpreference1 extends State<Userpreference1> {
  //Text controller
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();

  //to track state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  //saving username and fullname
  Future<void> saveNickname() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
        'username': usernameController.text,
        'fullname': fullnameController.text,
      }, SetOptions(merge: true));
    }
  }

  void goToUserpreference2(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // Only navigate if validation is successful
      Navigator.pushNamed(context, '/Userpreference2Page');
    }
  }

  void goToLoginPage(BuildContext context) {
    Navigator.pushNamed(context, '/LoginPage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),

      //linear percent indicator?
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: LinearPercentIndicator(
            backgroundColor: AppColors.indicatorBg,
            progressColor: AppColors.indicatorProgress,
            percent: 0,
            barRadius: Radius.circular(5),
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

              //fullname field

              MyTextfield(
                hintText: 'Enter your name',
                obscureText: false,
                controller: fullnameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

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

              MyTextfield(
                hintText: 'Enter your username',
                obscureText: false,
                controller: usernameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),

              SizedBox(
                height: 20,
              ),

              Center(
                child: Container(
                  height: 250,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '+ Add image here',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: 25,
              ),

              // lower buttons back and continue
              Row(
                children: [
                  //back button w/ gesture detector
                  GestureDetector(
                    onTap: () {
                      goToLoginPage(context);
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
                          await saveNickname();
                          if (_formKey.currentState!.validate()) {
                            goToUserpreference2(context);
                          }
                        }),
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
