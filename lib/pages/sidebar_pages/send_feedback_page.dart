import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:fitness/widgets/components/my_textfield.dart';
import 'package:flutter/material.dart';

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({super.key});

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'Bug';
  bool _isSubmitting = false;

  // Feedback categories
  final List<String> _categories = [
    'Bug',
    'Suggestion',
    'Inquiry',
    'Feature Request',
    'Complaint',
    'Other'
  ];

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to submit feedback')),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('feedback').add({
          'userId': user.uid,
          'userEmail': user.email,
          'category': _selectedCategory,
          'message': _feedbackController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'new', // new, reviewed, in-progress, resolved
          'appVersion': '1.0.0', // You can get this from package_info plugin
          'deviceInfo': 'Unknown', // You can get this from device_info plugin
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );

        // Clear the form
        _feedbackController.clear();
        setState(() => _selectedCategory = 'Bug');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Send Feedback',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Dropdown
              Text(
                'Category',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: Colors.grey[900],
                  style: TextStyle(color: AppColors.primaryText),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedCategory = newValue!);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Feedback Text Area
              Text(
                'Your Feedback',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackController,
                maxLines: 8,
                maxLength: 1000,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Please describe your feedback in detail...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your feedback';
                  }
                  if (value.length < 10) {
                    return 'Feedback should be at least 10 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              Center(
                child: MyButtons(
                  text: 'Submit Feedback',
                  onTap: _isSubmitting ? null : _submitFeedback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
