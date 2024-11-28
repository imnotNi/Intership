import 'package:flutter/material.dart';
import 'package:urbanharmony/models/user.dart';
import 'package:urbanharmony/pages/profile_page.dart';

class MyUserTile extends StatelessWidget {
  final UserProfile user;
  const MyUserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(user.name),
        titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        subtitle: Text('@${user.username}'),
        subtitleTextStyle:
            TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        leading: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(uid: user.uid),
          ),
        ),
      ),
    );
  }
}
