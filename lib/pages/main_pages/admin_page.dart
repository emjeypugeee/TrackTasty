import 'package:fitness/provider/user_provider.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness/pages/admin/dashboard_section.dart';
import 'package:fitness/pages/admin/account_management_section.dart';
import 'package:fitness/pages/admin/chatbot_management_section.dart';
import 'package:fitness/pages/admin/feedback_management_section.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final List<Widget> _adminSections = [
    const DashboardSection(),
    const AccountManagementSection(),
    const ChatbotManagementSection(),
    const FeedbackManagementSection(),
  ];

  void _showlogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomTextButton(
                    title: 'Back',
                    onTap: () {
                      Navigator.pop(dialogContext);
                    },
                    size: 20),
              ),
              Expanded(
                child: MyButtons(
                  text: 'Log out',
                  onTap: () async {
                    // log out the user
                    dialogContext.read<UserProvider>().logout();
                    Navigator.pop(dialogContext);
                    context.go('/startup');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _showlogout(context);
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _adminSections[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }
}
