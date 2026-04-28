import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import '../provider/account.dart';
import '../provider/settings.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import 'settings.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsDataProvider>(context);
    final accountProvider = Provider.of<AccountDataProvider>(context);

    return UnauthorizedPageSkeleton(
        children: [
          SettingsPage.buildButton(theme, "Starten", Icons.chevron_right_rounded, () => context.push(settingsProvider.onboarding ? "/setup" : "/home")),
          const SizedBox(height: 25),

         CustomLineBreakText(
              """Hier entsteht die Startseite deiner Notenapp. Bald findest du hier alle wichtigen Infos und Funktionen auf einen Blick.
Schon jetzt kannst du deinen Notendurchschnitt berechnen, Prognosen erstellen und die besten Einbringungen automatisch bestimmen – perfekt abgestimmt auf das neue G9 in Bayern.
Tippe auf Starten, um direkt loszulegen.
Falls du die App bereits genutzt hast, kannst du dich auch mit deinem Account anmelden, um deine Daten zu synchronisieren.""",
              style: theme.textTheme.bodySmall
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              if (!accountProvider.isLoggedIn) GestureDetector(
                onTap: () async {
                  Api.doGoogleLoginAndSync(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login_rounded, color: theme.primaryColor, size: 18,),
                      const SizedBox(width: 10,),
                      Text("Login", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ],

                  ),
                ),
              ) else Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor, width: 2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_circle_rounded, color: theme.primaryColor, size: 18,),
                    const SizedBox(width: 10,),
                    Text("${accountProvider.userProfile?.name}", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16)),
                  ],

                ),
              ),
              GestureDetector(
                onTap: () async {
                  // launch url
                  const url = "https://github.com/anweisen/G9";
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, color: theme.primaryColor, size: 18,),
                      const SizedBox(width: 10,),
                      Text("GitHub", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ],

                  ),
                ),
              ),
            ],
          ),
        ],
    );
  }
}
