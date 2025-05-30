import 'package:fitness/components/my_buttons.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF121212),
        child: ListView(
          children: [
            DrawerHeader(
              child: Center(
                child: Image.asset('lib/images/TrackTastyLogo.png'),
              ),
            ),
            ExpansionTile(
              leading: Icon(Icons.edit),
              title: Text(
                'Edit Profile',
                style: TextStyle(color: AppColors.primaryText),
              ),
              children: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Name',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(
                    'Edit Goals',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
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
              leading: Icon(Icons.feed_outlined),
              title: Text(
                'Terms and Conditions',
                style: TextStyle(color: AppColors.primaryText),
              ),
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text(
                'Feedback',
                style: TextStyle(color: AppColors.primaryText),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text(
                'Settings',
                style: TextStyle(color: AppColors.primaryText),
              ),
            ),
            ListTile(
              leading: Icon(Icons.people_rounded),
              title: Text(
                'About Us',
                style: TextStyle(color: AppColors.primaryText),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text(
                'Log Out',
                style: TextStyle(color: AppColors.primaryText),
              ),
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextButton(title: 'Back', onTap: () {}, size: 20),
                        ),
                        Expanded(
                          child: MyButtons(
                            text: 'Log out',
                            onTap: () {
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
