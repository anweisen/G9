import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Nav extends StatelessWidget {
  const Nav({super.key});

  int _getCurrentIndex(BuildContext context) {
    String? routeName = ModalRoute.of(context)?.settings.name;
    switch (routeName) {
      case "/settings":
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

  void _navigateToRoute(int currentIndex, int targetIndex, String targetRoute, BuildContext context) {
    if (currentIndex == targetIndex) return;
    context.go(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: theme.scaffoldBackgroundColor.withOpacity(.4),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            bottom: true,
            right: true,
            left: true,
            top: false,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: BottomNavigationBar(
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _getCurrentIndex(context),
                  backgroundColor: Colors.transparent,
                  fixedColor: theme.primaryColor,
                  iconSize: 28,
                  elevation: 0,
                  selectedLabelStyle: const TextStyle(fontSize: 1),
                  unselectedLabelStyle: const TextStyle(fontSize: 1),
                  onTap: (int index) {
                    var currentIndex = _getCurrentIndex(context);
                    if (index == currentIndex) return;
                    if (index == 0) {
                      _navigateToRoute(currentIndex, 0, "/home", context);
                    } else if (index == 1) {
                      _navigateToRoute(currentIndex, 1, "/subjects", context);
                    } else if (index == 2) {
                      _navigateToRoute(currentIndex, 2, "/results", context);
                    } else if (index == 3) {
                      _navigateToRoute(currentIndex, 3, "/settings", context);
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
            ),
          ),
        ),
      ),
    );
  }
}
