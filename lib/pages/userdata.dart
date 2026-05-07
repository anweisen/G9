import 'package:flutter/material.dart';

import '../widgets/skeleton.dart';

class UserDataPage extends StatelessWidget {
  const UserDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MarkdownPage(assetsPath: "assets/content/userdata.md", errorName: "Accountdaten Erklärung");
  }
}
