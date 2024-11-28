import 'package:flutter/material.dart';
import 'package:urbanharmony/models/post.dart';
import 'package:urbanharmony/pages/account_settings_page.dart';
import 'package:urbanharmony/pages/blocked_users_page.dart';
import 'package:urbanharmony/pages/home_page.dart';
import 'package:urbanharmony/pages/post_page.dart';
import 'package:urbanharmony/pages/profile_page.dart';

void goUserPage(BuildContext context, String uid) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfilePage(uid: uid),
    ),
  );
}

void goPostPage(BuildContext context, Post post) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PostPage(post: post),
    ),
  );
}

void goBlockedUsersPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BlockedUsersPage(),
    ),
  );
}

void goAccountSettingsPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AccountSettingsPage(),
    ),
  );
}

void goHomePage(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => HomePage(),
    ),
    (route) => route.isFirst,
  );
}
