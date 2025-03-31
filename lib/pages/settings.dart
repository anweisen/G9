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
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/setup");
            },
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.primaryColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Wahl ändern", style: theme.textTheme.labelMedium),
                    Icon(Icons.published_with_changes, color: theme.textTheme.labelMedium?.color, size: 16),
                  ],
                ),
            ),
          ),

          const SizedBox(height: 30),

          ...SetupFinishPage.buildSubjects(choice, theme)
        ]);
  }
}
