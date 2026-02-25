import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../provider/account.dart';
import '../provider/settings.dart';
import '../widgets/subpage.dart';
import '../widgets/skeleton.dart';
import 'setup.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    var accountProvider = Provider.of<AccountDataProvider>(context);
    var choice = Provider.of<SettingsDataProvider>(context).choice;

    return PageSkeleton(
        title: const PageTitle(title: "Präferenzen"),
        children: [
          const SizedBox(height: 8),

          if (accountProvider.userProfile != null && accountProvider.accessToken != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor, width: 4),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(accountProvider.userProfile!.picture, width: 44, height: 44, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle_rounded, size: 40))
                      ),
                      const SizedBox(width: 16,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("angemeldet als", style: theme.textTheme.bodySmall),
                          Text(accountProvider.userProfile!.name, style: theme.textTheme.bodyMedium),
                        ],
                      )
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => accountProvider.logout(),
                    child: Icon(Icons.logout_rounded, size: 24, color: theme.indicatorColor,)
                  )
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => Api.handleGoogleAuth(accountProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor, width: 4),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_circle_rounded, size: 38, color: theme.shadowColor,),
                        const SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("anmelden", style: theme.textTheme.bodyMedium?.copyWith(height: 1.2)),
                            Text("mit Google", style: theme.textTheme.bodySmall),
                          ],
                        )
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.login_rounded, size: 24, color: theme.primaryColor,)
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          if (choice != null)
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

  static Widget buildButton(ThemeData theme, String text, IconData icon, Function()? onTap, {bool primary = true}) {
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
            Expanded(child: Text(text, style: (primary ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium), overflow: TextOverflow.ellipsis, maxLines: 1, softWrap: true,)),
            const SizedBox(width: 16),
            Icon(icon, color: (primary ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)?.color, size: 18),
          ],
        ),
      ),
    );
  }
}
