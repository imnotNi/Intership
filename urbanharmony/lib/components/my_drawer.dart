import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/components/my_drawer_tile.dart';
import 'package:urbanharmony/pages/admin_page.dart';
import 'package:urbanharmony/pages/design_page.dart';
import 'package:urbanharmony/pages/feedback_page.dart';
import 'package:urbanharmony/pages/game_page.dart';
import 'package:urbanharmony/pages/profile_page.dart';
import 'package:urbanharmony/pages/search_page.dart';
import 'package:urbanharmony/pages/settings_page.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';

class MyDrawer extends StatefulWidget {
  MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? userRole;

  final _auth = AuthService();
  @override
  void initState() {
    super.initState();
    _getUserRole();
  }
  void logout() {
    _auth.logout();
  }
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      return userDoc['role'];
    } catch (e) {
      print(e);
      return null;
    }
  }
  Future<void> _getUserRole() async {
    String? role = await getUserRole(_auth.getCurrentUID());
    setState(() {
      userRole = role;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: ListView(
            //logo
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Divider(
                indent: 25,
                endIndent: 25,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(
                height: 10,
              ),
              //home
              Expanded(
                child: MyDrawerTile(
                  title: "H O M E".tr,
                  icon: Icons.home,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: MyDrawerTile(
                  title: "P R O F I L E".tr,
                  icon: Icons.person,
                  onTap: () {
                    Navigator.pop(context);
                    //go to profile
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfilePage(uid: _auth.getCurrentUID()),
                        ),
                    );
                  },
                ),
              ),
              Expanded(
                child: MyDrawerTile(
                  title: "S E A R C H".tr,
                  icon: Icons.search,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchPage(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: MyDrawerTile(
                  title: "S E T T I N G S".tr,
                  icon: Icons.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: MyDrawerTile(
                  title: "F E E D B A C K".tr,
                  icon: Icons.feedback,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackPage(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: MyDrawerTile(
                  title: "D E S I G N".tr,
                  icon: Icons.format_paint,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DesignPage(),
                      ),
                    );
                  },
                ),
              ),
              userRole == 'Admin' ? Expanded(
                child: MyDrawerTile(
                  title: "A D M I N".tr,
                  icon: Icons.admin_panel_settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomePage(),
                      ),
                    );
                  },
                ),
              ) : Spacer(),
              const Spacer(),
              //logout
              MyDrawerTile(
                  title: "L O G O U T".tr, icon: Icons.logout, onTap: logout)
            ],
          ),
        ),
      ),
    );
  }
}
