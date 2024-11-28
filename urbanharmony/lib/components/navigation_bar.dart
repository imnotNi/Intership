import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      unselectedItemColor: Theme.of(context).colorScheme.secondary,
      selectedItemColor: Theme.of(context).colorScheme.inversePrimary,
      backgroundColor: Theme.of(context).colorScheme.primary,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      items:  [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Products'.tr,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.comment),
          label: 'Feedbacks'.tr,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Users'.tr,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Category'.tr,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report),
          label: 'Reports'.tr,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.browse_gallery),
          label: 'Background'.tr,
        ),


      ],
    );
  }
}
