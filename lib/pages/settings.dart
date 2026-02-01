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
          ...SetupFinishPage.buildSubjects(choice, theme),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              const minButtonWidth = 240.0;
              final buttonWidth = constraints.maxWidth >= (minButtonWidth * 2 + spacing) ? constraints.maxWidth / 2 - spacing : constraints.maxWidth;
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: spacing,
                runSpacing: 12,
                children: [
                  SizedBox(width: buttonWidth, child: buildButton(theme, "Wahl ändern", Icons.settings_backup_restore_rounded, () => Navigator.pushNamed(context, "/setup"))),
                  SizedBox(width: buttonWidth, child: buildButton(theme, "Abifächer ändern", Icons.published_with_changes_rounded, () => Navigator.pushNamed(context, "/setup/abi"))),
                ],
              );
            }
          ),
          const SizedBox(height: 14),
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
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: (primary ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)),
            const SizedBox(width: 16),
            Icon(icon, color: (primary ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)?.color, size: 16),
          ],
        ),
      ),
    );
  }
}
