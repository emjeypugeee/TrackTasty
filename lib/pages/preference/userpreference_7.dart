import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:fitness/widgets/components/gender_button.dart';

class Userpreference7 extends StatefulWidget {
  const Userpreference7({super.key});

  @override
  State<Userpreference7> createState() => _Userpreference7();
}

class _Userpreference7 extends State<Userpreference7> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, double> macros = {};
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: LinearPercentIndicator(
          backgroundColor: AppColors.indicatorBg,
          progressColor: AppColors.indicatorProgress,
          percent: 1,
          barRadius: const Radius.circular(5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start your Nutrition Journey',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 22),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Thank you for providing your information! We\'re now calculating your personalized daily macronutrient recommendations based on your inputs',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Here\'s your recommended daily macronutrient intake. Feel free to adjust any of your information to match your progress!',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // MACROS

              const SizedBox(height: 20),

              //lower buttons back and continue button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    //back button with gesture detectore
                    CustomTextButton(
                        title: 'Back',
                        onTap: () {
                          context.push('/preference6');
                        },
                        size: 16),

                    SizedBox(width: 50),

                    //continue button
                    Expanded(
                      child: MyButtons(
                        text: 'Next',
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Saved!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.snackBarBgSaved,
                            ));
                            context.push('/home');
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
      ),
    );
  }

  Widget _buildMacroItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
