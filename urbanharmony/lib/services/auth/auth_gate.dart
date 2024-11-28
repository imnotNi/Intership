import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:urbanharmony/pages/home_page.dart';
import 'package:urbanharmony/pages/start_page.dart';
import 'package:urbanharmony/services/auth/login_or_register.dart';

import '../../pages/admin_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      return userDoc['role'];
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Check if logged in
          if (snapshot.hasData) {
            // final user = snapshot.data!;
            // return FutureBuilder<String?>(
            //   future: getUserRole(user.uid),
            //   builder: (context, roleSnapshot) {
                // if (roleSnapshot.connectionState == ConnectionState.waiting) {
                //   return const Center(child: CircularProgressIndicator());
                // }
                // if (roleSnapshot.hasError || !roleSnapshot.hasData) {
                //   return Center(child: Text('Error fetching role'));
                // }
                // final role = roleSnapshot.data;
                // // Navigate based on role
                // if (role == 'Admin') {
                //   return const AdminHomePage();
                // } else {
                  return const StartPage();
                // }
            //   },
            // );
          }
          // If not logged in
          return const LoginOrRegister();
        },
      ),
    );
  }
}
