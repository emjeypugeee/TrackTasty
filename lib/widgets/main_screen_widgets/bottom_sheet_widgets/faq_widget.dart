import 'package:flutter/material.dart';
import 'package:fitness/theme/app_color.dart';

class FAQWidget extends StatelessWidget {
  const FAQWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Center(
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Divider(
              color: AppColors.primaryText.withOpacity(0.3),
              thickness: 1,
            ),
            const SizedBox(height: 20),

            // GETTING STARTED & ACCOUNT SECTION
            Text(
              'Getting Started & Account',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: How do I create a TrackTasty account?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: On the startup page, select "Sign Up" or "Register." You will be guided through creating a new account that you can use to log in.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: I forgot my password. What should I do?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: On the login page, use the "Forget Password" option. You will be able to reset your password after verifying your identity through your registered email.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: Why do I need to provide my personal information during sign-up?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: This information is essential for our system to accurately calculate your personalized daily calorie needs and macronutrient goals (carbs, fats, and protein). This ensures your meal plans and tracking are tailored specifically to you.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: What are dietary preferences and allergies used for?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: Your dietary preferences (e.g., vegetarian, keto) help our chatbot prioritize foods you enjoy when generating meal plans. Your allergies are used to avoid suggesting foods that may be harmful to you.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // UNDERSTANDING MACRO TRACKING
            Text(
              'Understanding Macro Tracking',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: What are macros and why should I track them?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: Macros (short for macronutrients) are the three main nutrients your body needs in large amounts: carbohydrates, proteins, and fats. Tracking them helps ensure you\'re getting the right balance of nutrients to support your fitness goals, whether it\'s weight loss, muscle gain, or maintenance.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: How does macro tracking differ from calorie counting?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: While calorie counting focuses only on total energy intake, macro tracking ensures you\'re getting the right proportions of proteins, carbs, and fats. This helps optimize body composition, energy levels, and overall health beyond just weight management.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: What if I go over my macros for one day?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: Don\'t worry! One day won\'t ruin your progress. Just return to your targets the next day. Consistency over time matters more than perfection every single day.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: How long does it take to see results from macro tracking?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: Most people notice changes in energy levels within 1-2 weeks, while physical changes typically become noticeable after 4-6 weeks of consistent tracking.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: What\'s the best way to measure food for accuracy?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: Use a food scale for solids, measuring cups for liquids, and track everything in the TrackTasty app immediately after measuring for best accuracy.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // USING THE APP & FEATURES SECTION
            Text(
              'Using the App & Features',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: What is shown on the Home Page?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: The Home Page is your dashboard. It displays your current progress towards your daily macro intake and allows you to view your data from the previous seven days.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: What can I ask the Chatbot?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: You can use the chatbot to:\n• Get general nutritional information.\n• Ask for recipes and create a personalized meal plan.\n• Find out the nutritional value of a specific food.\n• Get food recommendations that you can easily log.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: What information is available on the Analytics Page?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: The Analytics page gives you a clear view of your progress with a graph of your calorie intake and a history of your weight logs. It also provides a forecast of your future weight based on your current habits.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: How do I log food I\'ve eaten?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: You can log food in four convenient ways:\n1. Manual Input: Enter the food details yourself.\n2. Search Database: Use the Food Page to search our extensive database.\n3. Camera Scan: Take a picture of your food for instant identification.\n4. Chatbot Recommendation: Ask the chatbot for a meal recommendation and log it directly from the chat.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // MANAGING MY PREFERENCES SECTION
            Text(
              'Managing My Preferences',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: Can I change my dietary preferences or allergies after signing up?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: Yes! You can update your dietary preferences and allergies at any time from the side drawer in the "Edit Food Preference" section. This will immediately influence future meal plan suggestions from the chatbot.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: What if my fitness goals change? Can I update my macro goals?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: Absolutely. You can recalculate your macronutrient goals at any time by clicking "Edit Goals" in the side drawer. Just update your information, and your new macros will be calculated for you.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: Can I set reminders to log my meals?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: Yes. You can manage your meal notifications in the "Notification Settings" within the side drawer. You can turn reminders on or off and set specific times for breakfast, lunch, and dinner notifications.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // SUPPORT SECTION
            Text(
              'Support',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: How can I report a bug or suggest a new feature?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: We value your feedback! Please use the "Send Feedback" page in the side drawer to share your experiences or suggestions.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Q: How do I report an issue with the chatbot?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A: If you encounter a problem with the chatbot, you can report it directly within the Chatbot Page. Click the settings icon and select "Report Chatbot Issue."',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
