import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  Future<void> signOutUser() async {
    await FirebaseAuth.instance.signOut();
  }

  // Editting username
  void _showEditUsernameDialog(BuildContext context) {
    TextEditingController usernameController = TextEditingController();

    Future<bool> saveNickname() async {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in!')),
          );
          return false;
        }

        // → Critical Fix: Use user.uid as document ID
        await FirebaseFirestore.instance.collection("Users").doc(user.email).set(
          {
            'username': usernameController.text,
          },
          SetOptions(merge: true), // ← Preserves existing fields
        );

        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        return false;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.containerBg,
        title: Center(
          child: Text(
            'Change your nickname:',
            style: TextStyle(color: AppColors.primaryText),
          ),
        ),
        content: MyTextfield(
          hintText: 'Nickname:',
          obscureText: false,
          controller: usernameController,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomTextButton(
                  title: 'Back',
                  onTap: () => Navigator.pop(context),
                  size: 20,
                ),
              ),
              Expanded(
                child: MyButtons(
                  text: 'Save',
                  onTap: () async {
                    bool success = await saveNickname();
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nickname updated successfully!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Editting goal and goal weight
  void _showEditGoalDialog(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    TextEditingController goalWeightController = TextEditingController();

    String dropDownValue = 'Maintain Weight';

    Future<bool> saveUserPreferences() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await FirebaseFirestore.instance.collection("Users").doc(user.email).set({
          'goalWeight': goalWeightController.text,
          'goal': dropDownValue,
        }, SetOptions(merge: true));
        return true;
      }
      return false;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.containerBg,
            title: Text(
              'Edit your goals',
              style: TextStyle(color: AppColors.primaryText),
            ),
            content: SizedBox(
              height: 250,
              width: screenWidth * 1,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Goal Weight:',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 20),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                  MyTextfield(
                      hintText: 'goal weight (kg)',
                      obscureText: false,
                      controller: goalWeightController),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Text(
                        'Goal:',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 20),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: dropDownValue,
                    dropdownColor: AppColors.containerBg,
                    hint: Text(
                      'Goal',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                    icon: Icon(Icons.arrow_downward),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropDownValue = newValue!;
                      });
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'Lose Weight',
                        child: Text(
                          'Lose Weight',
                          style: TextStyle(color: AppColors.primaryText),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Maintain Weight',
                        child: Text(
                          'Maintain Weight',
                          style: TextStyle(color: AppColors.primaryText),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Gain Weight',
                        child: Text(
                          'Gain Weight',
                          style: TextStyle(color: AppColors.primaryText),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: CustomTextButton(
                          title: 'Back',
                          onTap: () => Navigator.pop(context),
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: MyButtons(
                          text: 'Save',
                          onTap: () async {
                            bool success = await saveUserPreferences();
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Goals updated successfully!')),
                              );
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
        },
      ),
    );
  }

  void _showlogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomTextButton(
                    title: 'Back',
                    onTap: () {
                      context.pop();
                    },
                    size: 20),
              ),
              Expanded(
                child: MyButtons(
                  text: 'Log out',
                  onTap: () {
                    signOutUser();
                    context.push('/login');
                  },
                ),
              ),
            ],
          )
        ],
        backgroundColor: AppColors.containerBg,
        title: Center(
          child: Text(
            'Log out?',
            style: TextStyle(color: AppColors.primaryText),
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  void _showAboutUs(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.containerBg,
        content: SizedBox(
          height: 250,
          width: screenWidth * 1,
          child: Column(
            children: [
              Center(
                child: Text(
                  'Mission',
                  style: TextStyle(
                      color: AppColors.primaryText, fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'To empower individuals to live healthier lives by making food tracking simple, smart, and supportive through technology and community.',
                style: TextStyle(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 5,
              ),
              Center(
                child: Text(
                  'Vision',
                  style: TextStyle(
                      color: AppColors.primaryText, fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'To become the go-to wellness companion that helps people build lasting healthy habits — one meal, one step, one goal at a time.',
                style: TextStyle(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsAndCondition(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.containerBg,
        title: Center(
          child: Text(
            'T&C',
            style: TextStyle(color: AppColors.primaryText),
          ),
        ),
        content: SizedBox(
          height: 500,
          width: screenWidth * 1,
          child: Column(
            children: [
              Text(
                '1. Acceptance of Terms \nBy using TrackTasty, you agree to follow these Terms and Conditions. If you do not agree, please do not use the app. \n\n 2. Purpose of the App \n TrackTasty is designed to help users track food intake, calories burned, and support healthy living. It is for informational purposes only and not a substitute for medical advice.',
                style: TextStyle(color: AppColors.secondaryText),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.drawerBg,
        child: ListView(
          children: [
            DrawerHeader(
              child: Center(
                child: Image.asset('lib/images/TrackTastyLogo.png'),
              ),
            ),
            ExpansionTile(
              childrenPadding: EdgeInsets.only(left: 50),
              leading: Icon(
                Icons.person,
                color: AppColors.drawerIcons,
              ),
              title: Text(
                'User Profile',
                style: TextStyle(color: AppColors.primaryText),
              ),
              children: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Username',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  onTap: () => _showEditUsernameDialog(context),
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Goals',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  onTap: () => _showEditGoalDialog(context),
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Food Preference',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                ),
              ],
            ),
            ListTile(
              leading: Icon(
                Icons.feed_outlined,
                color: AppColors.drawerIcons,
              ),
              title: Text(
                'Terms and Conditions',
                style: TextStyle(color: AppColors.primaryText),
              ),
              onTap: () => _showTermsAndCondition(context),
            ),
            ListTile(
              leading: Icon(Icons.feedback, color: AppColors.drawerIcons),
              title: Text(
                'Feedback',
                style: TextStyle(color: AppColors.primaryText),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: AppColors.drawerIcons),
              title: Text(
                'Settings',
                style: TextStyle(color: AppColors.primaryText),
              ),
            ),
            ListTile(
              leading: Icon(Icons.people_rounded, color: AppColors.drawerIcons),
              title: Text(
                'About Us',
                style: TextStyle(color: AppColors.primaryText),
              ),
              onTap: () => _showAboutUs(context),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              contentPadding: EdgeInsets.only(top: 320, left: 20),
              title: Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _showlogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
