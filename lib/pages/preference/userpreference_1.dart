import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class Userpreference1 extends StatefulWidget {
  const Userpreference1({super.key});

  @override
  State<Userpreference1> createState() => _Userpreference1();
}

class _Userpreference1 extends State<Userpreference1> {
  File? image;
  bool _isLoading = false;

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

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
        'fullname': fullnameController.text,
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
                        'First, how would you want us to address you?',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Profile Picture',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Center(
                            child: image != null
                                ? ClipOval(
                                    child: Image.file(
                                      image!,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    height: 110,
                                    width: 110,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(80),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                MyButtons(
                                    text: 'Upload photo',
                                    onTap: () {
                                      uploadImage(ImageSource.gallery);
                                    }),
                                const SizedBox(height: 5),
                                MyButtons(
                                    text: 'Take a picture',
                                    onTap: () {
                                      uploadImage(ImageSource.camera);
                                    })
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Full Name',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 5),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Username',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 5),
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
                      const SizedBox(height: 20),
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
                                  try {
                                    await saveNickname();
                                    if (mounted) {
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
