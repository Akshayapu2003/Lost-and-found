import 'package:flutter/material.dart';
import 'package:main/Screens/_profile.dart';
import 'package:main/Screens/home.dart';
import 'package:main/Screens/items.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  int currentPage = 0;
  List<Widget> pages = [
    const HomeScreen(),
    const ItemScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages.elementAt(currentPage),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
              icon: Icon(
                Icons.home,
                color: Colors.white,
              ),
              label: ""),
          NavigationDestination(
              icon: Icon(
                Icons.navigation,
                color: Colors.white,
              ),
              label: ""),
          NavigationDestination(
              icon: Icon(
                Icons.person,
                color: Colors.white,
              ),
              label: ""),
        ],
        selectedIndex: currentPage,
        onDestinationSelected: (int value) {
          setState(
            () {
              currentPage = value;
            },
          );
        },
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        height: 70,
      ),
    );
  }
}
