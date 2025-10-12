//
// Account Management Section
//
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

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
                          _buildEditField('Weight (kg)', weightController,
                              isNumber: true),
                          _buildEditField('Height (cm)', heightController,
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
                  'Admin', (userData['isAdmin'] ?? false).toString()),
              _buildUserDetailRow(
                  'Age', userData['age']?.toString() ?? 'Not set'),
              _buildUserDetailRow(
                  'Weight', userData['weight']?.toString() ?? 'Not set'),
              _buildUserDetailRow(
                  'Height', userData['height']?.toString() ?? 'Not set'),
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
