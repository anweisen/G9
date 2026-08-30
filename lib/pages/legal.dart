import 'package:flutter/material.dart';

import '../widgets/skeleton.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarkdownPage(assetsPath: "assets/content/legal.md", errorName: "Datenschutzerklärung und Impressum");
  }
}
