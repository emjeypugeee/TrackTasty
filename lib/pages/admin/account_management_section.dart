//
// Account Management Section
//
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccountManagementSection extends StatefulWidget {
  const AccountManagementSection({super.key});

  @override
  State<AccountManagementSection> createState() =>
      _AccountManagementSectionState();
}

class _AccountManagementSectionState extends State<AccountManagementSection> {
  final TextEditingController _emailController = TextEditingController();
  List<QueryDocumentSnapshot> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('Users').get();

      setState(() {
        _users = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUserAccount(String userId, String userEmail) async {
    TextEditingController emailVerificationController = TextEditingController();

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.grey[900],
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete the account for $userEmail? This action cannot be undone.',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To confirm, please type the email address exactly as shown below:',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailVerificationController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type the email address here...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      errorText: emailVerificationController.text.isNotEmpty &&
                              emailVerificationController.text != userEmail
                          ? 'Email does not match'
                          : null,
                    ),
                    onChanged: (value) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: emailVerificationController.text == userEmail
                            ? () => Navigator.pop(context, true)
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor:
                              emailVerificationController.text == userEmail
                                  ? Colors.red
                                  : Colors.grey[700],
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmDelete != true) return;

    try {
      // Delete user data from Firebase
      await FirebaseFirestore.instance.collection('Users').doc(userId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted successfully')),
      );

      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  Future<void> _editUserData(QueryDocumentSnapshot user) async {
    final userData = user.data() as Map<String, dynamic>;

    // Controllers and Variables for Editing User Data
    TextEditingController ageController =
        TextEditingController(text: userData['age']?.toString() ?? '');
    TextEditingController weightController =
        TextEditingController(text: userData['weight']?.toString() ?? '');
    TextEditingController heightController =
        TextEditingController(text: userData['height']?.toString() ?? '');
    TextEditingController usernameController =
        TextEditingController(text: userData['username']?.toString() ?? '');
    TextEditingController goalWeightController =
        TextEditingController(text: userData['goalWeight']?.toString() ?? '');

    String? selectedGoal = userData['goal'];
    String? selectedDietaryPreference = userData['dietaryPreference'];
    List<String> selectedAllergies =
        List<String>.from(userData['allergies'] ?? []);

    final List<String> goals = [
      'Lose Weight',
      'Mild Lose Weight',
      'Maintain Weight',
      'Mild Gain Weight',
      'Gain Weight'
    ];

    final List<String> dietaryPreferences = [
      'Omnivore',
      'Vegetarian',
      'Vegan',
      'Pescatarian',
      'Keto',
      'Paleo'
    ];

    final List<String> commonAllergies = [
      'Crustacean Shellfish',
      'Dairy (Milk)',
      'Egg',
      'Fish',
      'Peanut',
      'Sesame',
      'Soy',
      'Tree Nuts',
      'Wheat'
    ];

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
            ),
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

                // Title
                Center(
                  child: Text(
                    'Edit User Information',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),

                // Scrollable form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEditField('Username', usernameController),
                          _buildEditField('Age', ageController, isNumber: true),
                          _buildEditField('Weight', weightController,
                              isNumber: true),
                          _buildEditField('Height', heightController,
                              isNumber: true),
                          _buildEditField('Goal Weight', goalWeightController,
                              isNumber: true),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Goal',
                                    style: TextStyle(color: Colors.white)),
                                DropdownButtonFormField<String>(
                                  value: selectedGoal,
                                  dropdownColor: Colors.grey[800],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  items: goals.map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedGoal = newValue;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Dietary Preference Dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dietary Preference',
                                    style: TextStyle(color: Colors.white)),
                                DropdownButtonFormField<String>(
                                  value: selectedDietaryPreference,
                                  dropdownColor: Colors.grey[800],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  items: dietaryPreferences
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedDietaryPreference = newValue;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Allergies
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Allergies',
                                    style: TextStyle(color: Colors.white)),
                                Wrap(
                                  spacing: 8.0,
                                  children: commonAllergies.map((allergy) {
                                    final isSelected =
                                        selectedAllergies.contains(allergy);
                                    return FilterChip(
                                      label: Text(allergy,
                                          style:
                                              TextStyle(color: Colors.white)),
                                      selected: isSelected,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedAllergies.add(allergy);
                                          } else {
                                            selectedAllergies.remove(allergy);
                                          }
                                        });
                                      },
                                      selectedColor: Colors.blue[800],
                                      checkmarkColor: Colors.white,
                                      backgroundColor: Colors.grey[700],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),

                // Cancel and Save Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _updateUserData(
                              user.id,
                              usernameController.text,
                              ageController.text,
                              weightController.text,
                              heightController.text,
                              goalWeightController.text,
                              selectedGoal,
                              selectedDietaryPreference,
                              selectedAllergies,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Save Changes',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white)),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            // Add input formatters and validators based on field type
            inputFormatters: isNumber
                ? [
                    if (label == 'Age')
                      FilteringTextInputFormatter.allow(RegExp(r"[0-9\']")),
                    if (label == 'Weight' ||
                        label == 'Height' ||
                        label == 'Goal Weight')
                      FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                    if (label == 'Age') LengthLimitingTextInputFormatter(3),
                    if (label == 'Weight' ||
                        label == 'Height' ||
                        label == 'Goal Weight')
                      LengthLimitingTextInputFormatter(6),
                  ]
                : [
                    // For username field
                    LengthLimitingTextInputFormatter(20),
                  ],
            validator: (value) {
              if (isNumber) {
                if (value == null || value.isEmpty) {
                  return null; // Allow empty fields in admin edit
                }

                if (label == 'Age') {
                  final age = double.tryParse(value) ?? 0;
                  if (age < 14 || age > 80) {
                    return 'Age can only range from 14-80';
                  }
                  if (value.length > 3) {
                    return 'Max 3 chars';
                  }
                } else if (label == 'Weight' || label == 'Goal Weight') {
                  final weight = double.tryParse(value) ?? 0;
                  // Note: You'll need access to userData['measurementSystem'] to determine metric/imperial
                  // For now using generic validation
                  if (weight < 20 || weight > 660) {
                    return 'Weight should be between 20-660';
                  }
                  final regex = RegExp(r'^\d{1,3}(\.\d{0,2})?$');
                  if (!regex.hasMatch(value)) {
                    return 'Invalid format';
                  }
                  if (value.length > 6) {
                    return 'Max 6 chars';
                  }
                } else if (label == 'Height') {
                  if (value.isEmpty) return null;

                  // Generic height validation - you may want to adapt this based on measurement system
                  final height = double.tryParse(value) ?? 0;
                  if (height < 50 || height > 300) {
                    return 'Height should be between 50-300';
                  }
                  final regex = RegExp(r'^\d{1,3}(\.\d{0,2})?$');
                  if (!regex.hasMatch(value)) {
                    return 'Invalid format';
                  }
                  if (value.length > 6) {
                    return 'Max 6 chars';
                  }
                }
              } else {
                // For username field
                if (value != null && value.length > 20) {
                  return 'Username must be 20 characters or less';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserData(
    String userId,
    String username,
    String age,
    String weight,
    String height,
    String goalWeight,
    String? goal,
    String? dietaryPreference,
    List<String> allergies,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'username': username.isNotEmpty ? username : null,
        'age': age.isNotEmpty ? int.tryParse(age) : null,
        'weight': weight.isNotEmpty ? double.tryParse(weight) : null,
        'height': height.isNotEmpty ? double.tryParse(height) : null,
        'goalWeight':
            goalWeight.isNotEmpty ? double.tryParse(goalWeight) : null,
        'goal': goal,
        'dietaryPreference': dietaryPreference,
        'allergies': allergies,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      updateData.removeWhere((key, value) => value == null);

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User data updated successfully')),
      );

      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user data: $e')),
      );
    }
  }

  void _viewUserDetails(QueryDocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    String dateCreatedString;

    final dateAccountCreated = userData['dateAccountCreated'];

    if (dateAccountCreated is int) {
      final createdYear = dateAccountCreated;
      dateCreatedString = 'Year $createdYear';
    } else if (dateAccountCreated is Timestamp) {
      final date = dateAccountCreated.toDate();
      final year = date.year.toString();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      dateCreatedString = '$year-$month-$day';
    } else {
      dateCreatedString = 'Unknown';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('User Details', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserDetailRow('Email', userData['email'] ?? 'Unknown'),
              _buildUserDetailRow(
                  'Username', userData['username'] ?? 'Unknown'),
              _buildUserDetailRow(
                  'Age', userData['age']?.toString() ?? 'Not set'),
              _buildUserDetailRow(
                  'Measurement System',
                  userData['measurementSystem'] == "US"
                      ? 'Imperial'
                      : 'Metric'),
              _buildUserDetailRow(
                  'Weight',
                  userData['weight'] != null
                      ? '${userData['weight']} ${userData['measurementSystem'] == "US" ? 'lbs' : 'kg'}'
                      : 'Not set'),
              _buildUserDetailRow(
                  'Height',
                  userData['height'] != null
                      ? '${userData['height']} ${userData['measurementSystem'] == "US" ? 'in' : 'cm'}'
                      : 'Not set'),
              _buildUserDetailRow(
                  'Goal Weight',
                  userData['goalWeight'] != null
                      ? '${userData['goalWeight']} ${userData['measurementSystem'] == "US" ? 'lbs' : 'kg'}'
                      : 'Not set'),
              _buildUserDetailRow('Goal', userData['goal'] ?? 'Not set'),
              _buildUserDetailRow('Dietary Preference',
                  userData['dietaryPreference'] ?? 'None'),
              _buildUserDetailRow(
                  'Allergies',
                  (userData['allergies'] as List<dynamic>?)?.join(', ') ??
                      'None'),
              _buildUserDetailRow('Created', dateCreatedString),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _viewUserFoodLogs(QueryDocumentSnapshot user) async {
    final userData = user.data() as Map<String, dynamic>;

    try {
      // Get the user document by its ID (document ID is the email)
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.id)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User document not found')),
        );
        return;
      }

      final userDetails = userDoc.data() as Map<String, dynamic>;
      final userId = userDetails['userId'] ?? "Unknown";

      if (userId == "Unknown") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found in document')),
        );
        return;
      }

      // Get all food logs for this user using their UID
      final foodLogsQuery = await FirebaseFirestore.instance
          .collection('food_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final foodLogs = foodLogsQuery.docs;

      if (foodLogs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No food logs found for this user')),
        );
        return;
      }

      // Sort food logs by date (newest first)
      foodLogs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aDate = aData['date'] as Timestamp;
        final bDate = bData['date'] as Timestamp;
        return bDate.compareTo(aDate);
      });

      // Show the food logs dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.grey[900],
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Food Logs - ${userData['email'] ?? 'Unknown'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a date to view food log details',
                          style:
                              TextStyle(color: Colors.grey[300], fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: foodLogs.length,
                            itemBuilder: (context, index) {
                              final foodLog = foodLogs[index];
                              final foodLogData =
                                  foodLog.data() as Map<String, dynamic>;
                              final date =
                                  (foodLogData['date'] as Timestamp).toDate();
                              final formattedDate =
                                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                              final totalCalories =
                                  (foodLogData['totalCalories'] ?? 0)
                                      .toDouble();
                              final totalCarbs =
                                  (foodLogData['totalCarbs'] ?? 0).toDouble();
                              final totalFat =
                                  (foodLogData['totalFat'] ?? 0).toDouble();
                              final totalProtein =
                                  (foodLogData['totalProtein'] ?? 0).toDouble();

                              return Card(
                                color: Colors.grey[800],
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    formattedDate,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    'Calories: ${totalCalories.round()} • Carbs: ${totalCarbs.round()}g • Fat: ${totalFat.round()}g • Protein: ${totalProtein.round()}g',
                                    style: TextStyle(
                                        color: Colors.grey[300], fontSize: 12),
                                  ),
                                  trailing: Icon(Icons.chevron_right,
                                      color: Colors.grey[400]),
                                  onTap: () {
                                    Navigator.pop(
                                        context); // Close the current dialog
                                    _viewFoodLogDetails(
                                        foodLog, formattedDate, user);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading food logs: $e')),
      );
    }
  }

// NEW METHOD: View Detailed Food Log
  void _viewFoodLogDetails(
      QueryDocumentSnapshot foodLog, String date, QueryDocumentSnapshot user) {
    final foodLogData = foodLog.data() as Map<String, dynamic>;
    final foods = foodLogData['foods'] as List<dynamic>? ?? [];

    final totalCalories = (foodLogData['totalCalories'] ?? 0).toDouble();
    final totalCarbs = (foodLogData['totalCarbs'] ?? 0).toDouble();
    final totalFat = (foodLogData['totalFat'] ?? 0).toDouble();
    final totalProtein = (foodLogData['totalProtein'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Food Log - $date',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Close current dialog
                          // Reopen the user food logs dialog
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _viewUserFoodLogs(
                                user); // You'll need access to the user object here
                          });
                        }),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Macros
                      Card(
                        color: Colors.grey[800],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Daily Macros',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMacroItem(
                                      'Calories', '${totalCalories.round()}'),
                                  _buildMacroItem(
                                      'Carbs', '${totalCarbs.round()}g'),
                                  _buildMacroItem(
                                      'Fat', '${totalFat.round()}g'),
                                  _buildMacroItem(
                                      'Protein', '${totalProtein.round()}g'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Food Items Header
                      Text(
                        'Food Items (${foods.length})',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Food Items List
                      if (foods.isEmpty)
                        Container(
                          height: 60,
                          alignment: Alignment.center,
                          child: Text(
                            'No food items logged',
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: foods.length,
                            itemBuilder: (context, index) {
                              final food = foods[index] as Map<String, dynamic>;
                              final calories =
                                  (food['calories'] ?? 0).toDouble();
                              final carbs = (food['carbs'] ?? 0).toDouble();
                              final fat = (food['fat'] ?? 0).toDouble();
                              final protein = (food['protein'] ?? 0).toDouble();

                              return Card(
                                color: Colors.grey[800],
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  title: Text(
                                    food['mealName'] ?? 'Unknown Food',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Cal: ${calories.round()} • C: ${carbs.round()}g • F: ${fat.round()}g • P: ${protein.round()}g',
                                        style: TextStyle(
                                            color: Colors.grey[300],
                                            fontSize: 12),
                                      ),
                                      if (food['servingSize'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Serving: ${food['servingSize']}',
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                  isThreeLine: food['servingSize'] != null,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for macro items
  Widget _buildMacroItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[300]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewUserWeightHistory(QueryDocumentSnapshot user) async {
    final userData = user.data() as Map<String, dynamic>;

    try {
      // Get user's measurement system
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.id)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User document not found')),
        );
        return;
      }

      final userDetails = userDoc.data() as Map<String, dynamic>;
      final userId = userDetails['userId'] ?? "Unknown";
      final measurementSystem = userDetails['measurementSystem'] ?? "Metric";
      final weightUnit = measurementSystem == "US" ? "lbs" : "kg";

      if (userId == "Unknown") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found in document')),
        );
        return;
      }

      // Get all weight history for this user using their UID
      final weightHistoryQuery = await FirebaseFirestore.instance
          .collection('weight_history')
          .where('userId', isEqualTo: userId)
          .get();

      final weightHistory = weightHistoryQuery.docs;

      if (weightHistory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No weight history found for this user')),
        );
        return;
      }

      // Sort weight history by date (newest first)
      weightHistory.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aDate = aData['date'] as Timestamp;
        final bDate = bData['date'] as Timestamp;
        return bDate.compareTo(aDate);
      });

      // Show the weight history dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.grey[900],
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Weight History - ${userData['email'] ?? 'Unknown'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Total entries: ${weightHistory.length}',
                          style:
                              TextStyle(color: Colors.grey[300], fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: weightHistory.length,
                            itemBuilder: (context, index) {
                              final weightEntry = weightHistory[index];
                              final weightData =
                                  weightEntry.data() as Map<String, dynamic>;
                              final date =
                                  (weightData['date'] as Timestamp).toDate();
                              final formattedDate =
                                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              final formattedTime =
                                  '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                              final weight =
                                  (weightData['weight'] ?? 0).toDouble();

                              return Card(
                                color: Colors.grey[800],
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    '$weight $weightUnit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$formattedDate at $formattedTime',
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[800],
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading weight history: $e')),
      );
    }
  }

  List<QueryDocumentSnapshot> _getFilteredUsers() {
    if (_searchQuery.isEmpty) return _users;

    return _users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final email = userData['email']?.toString().toLowerCase() ?? '';
      final username = userData['username']?.toString().toLowerCase() ?? '';
      return email.contains(_searchQuery.toLowerCase()) ||
          username.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'User List (${filteredUsers.length} users)',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextFormField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final userData =
                                user.data() as Map<String, dynamic>;
                            final isAdmin = userData['isAdmin'] ?? false;

                            return Card(
                              color: Colors.grey[850],
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  userData['email'] ?? 'Unknown',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  userData['username'] ?? 'No username',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton(
                                      color: AppColors.containerBg,
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'details',
                                          child: Text('View Details',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryText)),
                                        ),
                                        PopupMenuItem(
                                          value: 'food_logs',
                                          child: Text('View Food Logs',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryText)),
                                        ),
                                        PopupMenuItem(
                                          value: 'weight_history',
                                          child: Text('View Weight History',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryText)),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit User Data',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryText)),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Account',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'details') {
                                          _viewUserDetails(user);
                                        } else if (value == 'food_logs') {
                                          _viewUserFoodLogs(user);
                                        } else if (value == 'weight_history') {
                                          _viewUserWeightHistory(user);
                                        } else if (value == 'edit') {
                                          _editUserData(user);
                                        } else if (value == 'delete') {
                                          _deleteUserAccount(user.id,
                                              userData['email'] ?? 'Unknown');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
