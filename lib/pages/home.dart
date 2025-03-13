import 'package:flutter/material.dart';
import 'package:expense_split/pages/dena.dart';
import 'package:expense_split/pages/lena.dart';
import 'package:expense_split/pages/settings.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

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

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [IconButton(onPressed: _signOut, icon: Icon(Icons.logout))],
      ),
      bottomNavigationBar: Navigation(
        setPageIndex: setPageIndex,
        currentIndex: _pageIndex,
      ),
      body: <Widget>[
        Lena(),
        Dena(),
        Settings(),
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
        NavigationDestination(icon: Icon(Icons.money), label: "Lena"),
        NavigationDestination(icon: Icon(Icons.wallet), label: "Dena"),
        NavigationDestination(icon: Icon(Icons.settings), label: "Setting"),
      ],
    );
  }
}
