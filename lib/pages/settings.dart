import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/settings.dart';
import '../widgets/skeleton.dart';
import 'setup.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    var choice = Provider.of<SettingsDataProvider>(context).choice!;

    return PageSkeleton(
        title: const PageTitle(title: "Präferenzen"),
        children: [

          const SizedBox(height: 10),
          buildButton(theme, "Wahl ändern", Icons.published_with_changes_rounded, () => Navigator.pushNamed(context, "/setup")),
          const SizedBox(height: 30),
          ...SetupFinishPage.buildSubjects(choice, theme),
          const SizedBox(height: 30),
          buildButton(theme, "Zur Startseite", Icons.info_rounded, () => Navigator.pushNamed(context, "/welcome"), primary: false),
          const SizedBox(height: 20),
        ]);
  }

  static Widget buildButton(ThemeData theme, String text, IconData icon, Function() onTap, {bool primary = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: primary ? theme.primaryColor : theme.dividerColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: (primary ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)),
            Icon(icon, color: (primary ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)?.color, size: 16),
          ],
        ),
      ),
    );
  }
}
