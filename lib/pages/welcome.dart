import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    const double leftOffset = PageSkeleton.leftOffset;

    return Scaffold(
      appBar: const WindowTitleBar(),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: leftOffset),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(builder: (context, constraints) => _buildTitleBar(theme, context, constraints)),
                      const SizedBox(height: 25),
                      SettingsPage.buildButton(theme, "Starten", Icons.chevron_right_rounded, () => Navigator.of(context).pushNamed(settingsProvider.onboarding ? "/setup" : "/home")),
                      const SizedBox(height: 40),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomLineBreakText(
                              """Hier entsteht die Startseite deiner Notenapp. Bald findest du hier alle wichtigen Infos und Funktionen auf einen Blick.
Schon jetzt kannst du deinen Notendurchschnitt berechnen, Prognosen erstellen und die besten Einbringungen automatisch bestimmen – perfekt abgestimmt auf das neue G9 in Bayern.
Tippe auf Starten, um direkt loszulegen.
Falls du die App bereits genutzt hast, kannst du dich auch mit deinem Account anmelden, um deine Daten zu synchronisieren.""",
                              style: theme.textTheme.bodySmall
                            ),

                            const SizedBox(height: 16),

                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                if (!accountProvider.isLoggedIn) GestureDetector(
                                  onTap: () async {
                                    Api.doGoogleLoginAndSync(context);
                                    Navigator.of(context).pushNamed(settingsProvider.onboarding ? "/setup" : "/home");
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

                            const Spacer(),
                            Center(child: Text("© 2025 anweisen", style: theme.textTheme.displayMedium)),
                          ],
                        ),
                  ),
                ]),
              ))),
    );
  }

  Widget _buildTitleBar(ThemeData theme, BuildContext context, BoxConstraints constraints) {
    bool isWide = constraints.maxWidth > 300;
    return Row(
      children: [
        SvgPicture.asset("assets/icons/logo.svg",
          clipBehavior: Clip.hardEdge,
          colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
          width: isWide ? 74 : 50,
          theme: SvgTheme(
            currentColor: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("G9 Notenapp",
                style: (isWide ? theme.textTheme.headlineMedium : theme.textTheme.bodyMedium),
                textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false)),
            Text("fürs Abitur in Bayern",
              // style: isWide ? theme.textTheme.labelSmall : theme.textTheme.displayMedium,
              style: theme.textTheme.displayMedium,
              textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false),
            ),
          ],
        )
      ],
    );
  }
}
