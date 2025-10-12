import 'package:flutter/material.dart';
import 'package:fitness/theme/app_color.dart';

class TermsConditionsWidget extends StatelessWidget {
  const TermsConditionsWidget({super.key});

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
                'Terms & Conditions',
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

            // 1. Acceptance of Terms
            Text(
              '1. ACCEPTANCE OF TERMS',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'By accessing or using TrackTasty ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to all terms, please discontinue use immediately. Continued use constitutes acceptance of any modifications.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 2. Service Description
            Text(
              '2. SERVICE DESCRIPTION',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TrackTasty is a macro-nutrient tracking application designed to help beginners monitor food intake, calculate nutritional requirements, and support weight management goals. The App provides personalized macro calculations based on user-provided information including age, gender assigned at birth, weight, height, activity level, weight goals, dietary preferences, and allergies.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 3. User GUIDELINES
            Text(
              '3. USER GUIDELINES',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• You must provide accurate and complete information for macro calculations\n• You agree to use the App only for lawful purposes\n• You must be at least 14 years old to use the App\n• You acknowledge that results may vary based on individual adherence',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 4. Medical Disclaimer
            Text(
              '4. MEDICAL DISCLAIMER',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TrackTasty provides nutritional information and tracking tools for informational purposes only. The App is not intended to diagnose, treat, cure, or prevent any disease or health condition. Always consult with a qualified healthcare professional before making significant changes to your diet or exercise routine. The macro calculations are estimates and should be used as guidelines rather than strict prescriptions.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 5. Data Collection and Privacy
            Text(
              '5. DATA COLLECTION AND PRIVACY',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We collect personal information (such as your preferences and app usage) to provide and improve our services. Your data is stored securely and handled according to our Privacy Policy. By using TrackTasty, you agree to the collection and processing of your data as described in our Privacy Policy. We comply with the Data Privacy Act of 2012 (Republic Act No. 10173) and ensure that your personal information is collected, used, and protected in accordance with Philippine data privacy laws.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 6. Intellectual Property
            Text(
              '6. INTELLECTUAL PROPERTY',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All content, features, and functionality developed by us for the TrackTasty application are owned by us and are protected by international copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, or create derivative works of our proprietary content without our explicit permission.\n\nHowever, the application utilizes data and services provided by third-party APIs, including but not limited to Gemini API (Google), FatSecret Platform (FatSecret), and DeepSeek API (DeepSeek). The use of any content, data, or functionality provided by these third-party APIs is governed by their respective terms of service and intellectual property policies. You acknowledge and agree that we are not the owners of this third-party content and are not responsible for your use of it.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 7. Limitation of Liability
            Text(
              '7. LIMITATION OF LIABILITY',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TrackTasty and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the App. This includes but is not limited to errors in macro calculations, nutritional information, or any health-related outcomes.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 8. Modifications to Terms
            Text(
              '8. MODIFICATIONS TO TERMS',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We reserve the right to modify these Terms and Conditions at any time. Continued use of the App after changes constitutes acceptance of the modified terms. Users will be notified of significant changes through the App or via email.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 9. Termination
            Text(
              '9. TERMINATION',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We may terminate or suspend your access to TrackTasty immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users or the App\'s operation.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Acceptance Note
            Center(
              child: Text(
                'By using TrackTasty, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
