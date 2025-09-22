import 'package:fitness/provider/registration_data_provider.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/selectable_Activity_Button.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

class Userpreference2 extends StatefulWidget {
  const Userpreference2({super.key});

  @override
  State<Userpreference2> createState() => _Userpreference2();
}

class _Userpreference2 extends State<Userpreference2> {
  int selectedIndex = -1; // Track selected button (-1 means no selection)

  //selectable acitvity button values
  final List<Map<String, String>> activityLevels = [
    {
      'title': 'Not active',
      'subtitle':
          '(You spend most of your time sitting and don\'t do any regular exercise)'
    },
    {
      'title': 'Lightly active',
      'subtitle': 'Light exercise or sports 1 to 3 days a week.)'
    },
    {
      'title': 'Moderately active',
      'subtitle':
          'You exercise or play sports consistently 4 to 5 times per week.'
    },
    {
      'title': 'Very active',
      'subtitle': 'Intense exercise or sports 6 to 7 days a week.'
    },
    {
      'title': 'Extra active',
      'subtitle':
          'Very intense, daily exercise or a highly demanding physical job.'
    },
  ];

  //saving activity levels thru firebase
  Future<void> saveUserActivityLevel() async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    provider.updateActivityLevel(activityLevels[selectedIndex]['title']!);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    await provider.loadFromPreferences(); // Load data from SharedPreferences

    // Pre-fill activity level if available
    final activityLevel = provider.userData.activityLevel;
    if (activityLevel != null) {
      selectedIndex =
          activityLevels.indexWhere((level) => level['title'] == activityLevel);
    }

    setState(() {}); // Update the UI after loading data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: SizedBox(
          width: double.infinity,
          child: LinearPercentIndicator(
            backgroundColor: AppColors.indicatorBg,
            progressColor: AppColors.indicatorProgress,
            percent: 0.16,
            barRadius: Radius.circular(5),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start your Nutrition Journey',
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Welcome to TrackTasty! We\'re excited to help you on your nutrition journey. To get started, we need a little information about you.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Next, how would you describe your activity level usually? Your activity level is essential for us to calculate your Daily Macro Intake, which will help us tailor a personalized nutrition plan just for you.',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 30),

                    // ------------------------
                    // Activity Level Selection
                    // ------------------------
                    Column(
                      children: List.generate(activityLevels.length, (index) {
                        return Selectableactivitybutton(
                          title: activityLevels[index]['title']!,
                          subtitle: activityLevels[index]['subtitle'],
                          isSelected: selectedIndex == index,
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 20), // Minimal bottom space
                  ],
                ),
              ),
            ),
            // Sticky Bottom Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  CustomTextButton(
                    title: 'Back',
                    onTap: () async {
                      final provider = Provider.of<RegistrationDataProvider>(
                          context,
                          listen: false);

                      // Save data before navigating back
                      if (selectedIndex != -1) {
                        provider.updateActivityLevel(
                            activityLevels[selectedIndex]['title']!);
                      }

                      context.push('/preference1');
                    },
                    size: 16,
                  ),
                  SizedBox(width: 50),
                  // Next button (expanded to fill remaining space)
                  Expanded(
                    child: MyButtons(
                      text: 'Next',
                      onTap: () async {
                        if (selectedIndex == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Please select your activity level'),
                            backgroundColor: AppColors.snackBarBgError,
                          ));
                        } else {
                          await saveUserActivityLevel();
                          context.push('/preference3');
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
    );
  }
}
