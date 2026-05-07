import 'package:flutter/material.dart';

import '../widgets/skeleton.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MarkdownPage(assetsPath: "assets/content/privacy.md", errorName: "Datenschutzinformationen");
  }
}
