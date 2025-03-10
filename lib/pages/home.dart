import 'package:flutter/material.dart';

import '../widgets/skeleton.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageSkeleton(
        title: PageTitle(title: "Übersicht"),
        children: [
          for (int i = 0; i < 50; i++)
            Center(child: Text("Home"))
        ]);
  }
}
