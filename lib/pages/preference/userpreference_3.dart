import 'package:fitness/provider/registration_data_provider.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/selectable_Activity_Button.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

class Userpreference3 extends StatefulWidget {
  const Userpreference3({super.key});

  @override
  State<Userpreference3> createState() => _Userpreference3();
}

class _Userpreference3 extends State<Userpreference3> {
  int selectedIndex = -1; // Track selected button (-1 means no selection)

  //selectable goal button values
  final List<Map<String, String>> activityLevels = [
    {'title': 'Lose Weight', 'subtitle': 'Lose 1 lb (0.5 kg) per week'},
    {'title': 'Mild Lose Weight', 'subtitle': 'Lose 0.5 lb (0.25 kg) per week'},
    {'title': 'Maintain Weight', 'subtitle': 'Keep your current weight'},
    {'title': 'Mild Gain Weight', 'subtitle': 'Gain 0.5 lb (0.25 kg) per week'},
    {'title': 'Gain Weight', 'subtitle': 'Gain 1 lb (0.5 kg) per week'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    await provider.loadFromPreferences(); // Load data from SharedPreferences

    // Pre-fill goal if available
    final goal = provider.userData.goal;
    if (goal != null) {
      selectedIndex = activityLevels.indexWhere((g) => g['title'] == goal);
    }

    setState(() {}); // Update the UI after loading data
  }

  // Save user preferences to Firestore
  Future<void> saveUserPreferences() async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    provider.updateGoal(activityLevels[selectedIndex]['title']!);
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
              percent: 0.32,
              barRadius: Radius.circular(5),
            ),
          )),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                      'Now, we need to know your goal. This information, combined with your age, gender, and activity level, will help us create a personalized nutrition plan just for you.',
                      style: TextStyle(color: Colors.grey),
                    ),

                    SizedBox(
                      height: 20,
                    ),

                    Text(
                      'Select your goal on using this application: \n',
                      style: TextStyle(color: Colors.white),
                    ),

                    // ---------------------
                    // Weight Goal Selection
                    // ---------------------
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
                            });
                      }),
                    ),

                    SizedBox(
                      height: 100,
                    ),
                  ],
                ),
              ),
            ),
            //lower buttons back and continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  //back button with gesture detectore
                  CustomTextButton(
                      title: 'Back',
                      onTap: () {
                        context.push('/preference2');
                      },
                      size: 16),

                  SizedBox(width: 50),

                  //continue button
                  Expanded(
                    child: MyButtons(
                      text: 'Next',
                      onTap: () async {
                        if (selectedIndex == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Please select your goal'),
                            backgroundColor: AppColors.snackBarBgError,
                          ));
                        } else {
                          await saveUserPreferences();
                          context.push('/preference4');
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
