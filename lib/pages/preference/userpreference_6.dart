import 'package:fitness/provider/registration_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class Userpreference6 extends StatefulWidget {
  const Userpreference6({super.key});

  @override
  State<Userpreference6> createState() => _Userpreference6();
}

class _Userpreference6 extends State<Userpreference6> {
  final List<Map<String, String>> allergies = [
    {
      'title': 'Crustacean Shellfish',
      'subtitle': 'e.g., Shrimp, crab, lobster, crawfish'
    },
    {'title': 'Dairy (Milk)', 'subtitle': 'e.g., Milk, cheese, butter, yogurt'},
    {'title': 'Egg', 'subtitle': 'e.g., Eggs, mayonnaise, custards'},
    {'title': 'Fish', 'subtitle': 'e.g., Tuna, salmon, cod, trout'},
    {'title': 'Peanut', 'subtitle': 'e.g., Peanuts, peanut butter, peanut oil'},
    {'title': 'Sesame', 'subtitle': 'e.g., Sesame seeds, tahini, sesame oil'},
    {'title': 'Soy', 'subtitle': 'e.g., Soybeans, edamame, tofu, soy sauce'},
    {
      'title': 'Tree Nuts',
      'subtitle': 'e.g., Almonds, walnuts, cashews, pecans'
    },
    {'title': 'Wheat', 'subtitle': 'e.g., Bread, pasta, flour, cereals'},
  ];

  Map<String, bool> selectedAllergies = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    await provider.loadFromPreferences();

    // Pre-fill allergies with their title as the key and a default value of false
    for (var item in allergies) {
      selectedAllergies[item['title']!] = false;
    }

    // Check and update the selected allergies from provider data
    if (provider.userData.allergies.isNotEmpty) {
      for (var allergyTitle in provider.userData.allergies) {
        selectedAllergies[allergyTitle] = true;
      }
    }

    setState(() {});
  }

  //saving user allergies
  Future<void> saveUserAllergies() async {
    final selected = selectedAllergies.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final provider =
        Provider.of<RegistrationDataProvider>(context, listen: false);
    provider.updateAllergies(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      //linear percent indicator?
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF121212),
          title: LinearPercentIndicator(
            backgroundColor: Color(0xFFe8def8),
            progressColor: Color(0xFF65558F),
            percent: 0.8,
            barRadius: Radius.circular(5),
          )),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
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
              'Lastly, please let us know about any allergies you have. We\'ll use this information to ensure that all of our meal recommendations are safe and free from those ingredients.',
              style: TextStyle(color: Colors.grey),
            ),

            SizedBox(
              height: 20,
            ),

            Text(
              'What are your known allergies?',
              style: TextStyle(
                color: Colors.white,
              ),
            ),

            SizedBox(
              height: 20,
            ),

            // ---------------------
            // Allergens Input
            // ---------------------
            Expanded(
                child: ListView(
              children: allergies.map((item) {
                final allergyTitle = item['title']!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Material(
                    color: const Color.fromARGB(255, 32, 32, 32),
                    borderRadius: BorderRadius.circular(20.0),
                    clipBehavior: Clip.antiAlias,
                    child: CheckboxListTile(
                      title: Text(
                        allergyTitle,
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        item['subtitle']!,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 20.0),
                      tileColor: selectedAllergies[allergyTitle] ?? false
                          ? AppColors.primaryColor
                              .withValues(alpha: 0.2) // Highlight color
                          : Colors.transparent,
                      value: selectedAllergies[allergyTitle] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          selectedAllergies[allergyTitle] = value!;
                        });
                      },
                      activeColor: AppColors.primaryColor,
                      checkColor: Colors.black,
                    ),
                  ),
                );
              }).toList(),
            )),

            SizedBox(
              height: 20,
            ),
            // lower buttons back and continue
            Row(
              children: [
                //back button w/ gesture detector
                CustomTextButton(
                    title: 'Back',
                    onTap: () {
                      context.push('/preference5');
                    },
                    size: 16),

                SizedBox(width: 50),

                //continue button
                Expanded(
                  child: MyButtons(
                    text: 'Next',
                    onTap: () async {
                      await saveUserAllergies();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Saved!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.snackBarBgSaved,
                        ));
                        context.push('/preference7');
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
  }
}
