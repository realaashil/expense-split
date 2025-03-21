import 'package:flutter/material.dart';
import 'package:expense_split/pages/dena.dart';
import 'package:expense_split/pages/lena.dart';
import 'package:expense_split/pages/settings_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _pageIndex = 0;
  void setPageIndex(int index) {
    setState(() {
      _pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("KarchaPaani"),
      ),
      bottomNavigationBar: Navigation(
        setPageIndex: setPageIndex,
        currentIndex: _pageIndex,
      ),
      body: <Widget>[
        Lena(),
        Dena(),
        SettingsScreen(),
      ][_pageIndex],
    );
  }
}

class Navigation extends StatelessWidget {
  final void Function(int) setPageIndex;
  final int currentIndex;
  const Navigation(
      {super.key, required this.setPageIndex, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: setPageIndex,
      destinations: <Widget>[
        NavigationDestination(
          icon: Icon(Icons.currency_bitcoin, color: Colors.green),
          label: "Lena",
        ),
        NavigationDestination(
            icon: Icon(
              Icons.wallet,
              color: Colors.red,
            ),
            label: "Dena"),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined, color: Colors.amber),
          label: "Setting",
          selectedIcon: Icon(
            Icons.settings,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}
