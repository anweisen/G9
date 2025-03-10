import 'dart:ui';

import 'package:flutter/material.dart';

class Nav extends StatelessWidget {
  const Nav({super.key});

  int _getCurrentIndex(BuildContext context) {
    String? routeName = ModalRoute.of(context)?.settings.name;
    switch (routeName) {
      case "/setup":
        return 3;
      case "/results":
        return 2;
      case "/subjects":
        return 1;
      case "/home":
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          currentIndex: _getCurrentIndex(context),
          backgroundColor: theme.scaffoldBackgroundColor.withOpacity(.6),
          fixedColor: theme.primaryColor,
          iconSize: 28,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 1),
          unselectedLabelStyle: const TextStyle(fontSize: 1),
          onTap: (int index) {
            var currentIndex = _getCurrentIndex(context);
            if (index == currentIndex) return;
            if (index == 0) {
              Navigator.pushNamed(context, '/home');
            } else if (index == 1) {
              Navigator.pushNamed(context, '/subjects');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/results');
            } else if (index == 3) {
              Navigator.pushNamed(context, '/setup');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart_outlined),
              activeIcon: Icon(Icons.table_chart),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
