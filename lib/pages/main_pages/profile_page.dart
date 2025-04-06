import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/components/my_buttons.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  // Current logged-in user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Future to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!
            .email) // Ensure your Firestore uses email as document ID
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0xFFFAA4A4),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          // If data is loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // If there's an error
          if (snapshot.hasError) {
            return Center(child: Text("Error loading profile"));
          }

          // If data is available
          if (snapshot.hasData && snapshot.data!.exists) {
            var userData = snapshot.data!.data();
            String username = userData?['username'] ??
                "Unknown User"; // Ensure 'username' field exists
            int joinedDate = userData?['dateAccountCreated'] ?? "Unknown User";

            return Column(
              children: [
                Container(
                  height: 280,
                  width: 410,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF262626),
                        Color(0xFF413939),
                        Color(0xFF363131),
                        Color(0xFF302D2D),
                        Color(0xFF886868),
                      ],
                      begin: Alignment.topCenter,
                    ),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(25.0)),
                  ),
                  padding: EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username, // Show the username from Firestore
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Joined $joinedDate',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Following | Followers',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Ranking',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum vestibulum.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MyButtons(text: 'Message', onTap: () {}),
                          SizedBox(width: 10),
                          MyButtons(text: 'Friends', onTap: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Center(child: Text("User not found"));
        },
      ),
    );
  }
}
