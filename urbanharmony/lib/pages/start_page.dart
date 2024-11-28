import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urbanharmony/components/my_drawer.dart';
import 'package:urbanharmony/pages/design_page.dart';
import 'package:urbanharmony/pages/home_page.dart';
import 'package:urbanharmony/pages/message_page.dart';
import 'package:urbanharmony/pages/products_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  Color mainColor = Colors.blueGrey;

  int _selectedIndex = 0;
  // Chỉ số trang hiện tại
  final List<Widget> _pages = [
    const HomePage(),
    ProductsPage(),
    MessagePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: MyDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0.0,
        title: Text(
          "UrbanHarmony",
          style: GoogleFonts.pacifico(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
       // actions: [
         // IconButton(
           // onPressed: () {},
           // color: Colors.black,
           // icon: const Icon(Icons.notifications, color: Colors.yellow),
         // ),
       // ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Theme.of(context).colorScheme.secondary,
        selectedItemColor: Theme.of(context).colorScheme.inversePrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Cập nhật chỉ số trang hiện tại
          });
        },
        items: [
          BottomNavigationBarItem(
            backgroundColor: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.home),
            label: 'Home'.tr,
          ),
          BottomNavigationBarItem(
            backgroundColor: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.list),
            label: 'Products'.tr,
          ),
          BottomNavigationBarItem(
            backgroundColor: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.chat),
            label: 'Message'.tr,
          ),
        ],
      ),
    );
  }
}
