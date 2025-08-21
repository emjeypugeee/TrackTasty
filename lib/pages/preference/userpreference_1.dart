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

class Userpreference1 extends StatefulWidget {
  const Userpreference1({super.key});

  @override
  State<Userpreference1> createState() => _Userpreference1();
}

enum Gender { male, female }

class _Userpreference1 extends State<Userpreference1> {
  Gender? selectedGender;
  File? image;
  bool _isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _ageFocusNode = FocusNode();

  // Image picker
  Future uploadImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() => this.image = imageTemporary);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.message}')),
      );
    }
  }

  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${user.uid}.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> saveNickname() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        return false;
      }

      String? imageUrl;
      if (image != null) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text('Uploading image...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );

        imageUrl = await uploadImageToFirebase(image!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
          return false;
        }
      }

      await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
        'username': usernameController.text,
        'age': ageController.text,
        'gender': selectedGender?.name,
        'profileImage': imageUrl,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return false;
    }
  }

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
          percent: 0,
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
                        'Welcome to TrackTasty! We’re excited to help you on your nutrition journey. To get started, we need a little information about you.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'What should we call you and how old are you?',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 20),

                      // ---------------------
                      // Username Input
                      // ---------------------
                      const Text(
                        'Username',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 5),
                      MyTextfield(
                        hintText: 'Enter your username',
                        obscureText: false,
                        controller: usernameController,
                        focusNode: _usernameFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _ageFocusNode.requestFocus();
                        },
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z ]')), // Letters + spaces only
                          LengthLimitingTextInputFormatter(30), // Max 30 chars
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ---------------------
                      // Age Input
                      // ---------------------
                      const Text(
                        'Age',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 5),
                      MyTextfield(
                        hintText: 'Enter your age',
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        focusNode: _ageFocusNode,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          _ageFocusNode.unfocus();
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: ageController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your age';
                          }
                          final age = int.tryParse(value);
                          if (age == null) {
                            return 'Please enter a valid number';
                          }
                          if (age < 14 || age > 80) {
                            return 'Please enter a valid age (14-80)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ---------------------
                      // Gender Selection
                      // ---------------------
                      Text(
                        'Please select your gender: \n',
                        style: TextStyle(color: Colors.white),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GenderIcon(
                              isSelected: selectedGender == Gender.male,
                              iconData: Icons.male,
                              onTap: () =>
                                  setState(() => selectedGender = Gender.male),
                              selectedColor: Colors.blue[800]!),
                          SizedBox(
                            width: 40,
                          ),
                          GenderIcon(
                              isSelected: selectedGender == Gender.female,
                              iconData: Icons.female,
                              onTap: () => setState(
                                  () => selectedGender = Gender.female),
                              selectedColor: Colors.pink[800]!)
                        ],
                      ),

                      SizedBox(
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ),

              // Sticky bottom buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    CustomTextButton(
                        title: 'Back',
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          context.push('/login');
                        },
                        size: 16),
                    const SizedBox(width: 50),
                    Expanded(
                      child: MyButtons(
                        text: _isLoading ? 'Loading...' : 'Next',
                        onTap: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isLoading = true);

                                  if (selectedGender == null) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text('Please select your gender'),
                                      backgroundColor:
                                          AppColors.snackBarBgError,
                                    ));
                                  }
                                  try {
                                    await saveNickname();

                                    if (mounted && selectedGender != null) {
                                      /*
                                      // Show success message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('Saved!'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor:
                                            AppColors.snackBarBgSaved,
                                      ));*/
                                      context.push('/preference2');
                                    }
                                  } catch (_) {
                                    // Error handled in saveNickname()
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
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
}
