import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/achievement_container.dart';
import 'package:fitness/widgets/main_screen_widgets/profile_screen/profile_container.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  // Current logged-in user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Future to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email) // Ensure your Firestore uses email as document ID
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            String username =
                userData?['username'] ?? "Unknown User"; // Ensure 'username' field exists
            int joinedDate = userData?['dateAccountCreated'];

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(0),
                  child: Column(
                    children: [
                      ProfileContainer(
                          name: username,
                          joinedDate: joinedDate,
                          ranking: '23',
                          following: '23',
                          userDescription: 'lorem ipsum dipsum dolor'),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Achievements',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Expanded(child: AchievementContainer()),
                                  SizedBox(width: 10),
                                  Expanded(child: AchievementContainer()),
                                ],
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

          //return if no user found
          return Center(child: Text("User not found"));
        },
      ),
    );
  }
}
