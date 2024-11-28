import 'package:flutter/material.dart';

class MyBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MyBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.brush),
          label: 'Designers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Consultations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star),
          label: 'Reviews',
        ),
      ],
    );
  }
}