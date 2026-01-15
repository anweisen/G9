import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../provider/settings.dart';
import '../widgets/skeleton.dart';
import 'settings.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final choice = Provider.of<SettingsDataProvider>(context).choice;

    const double leftOffset = PageSkeleton.leftOffset;

    print(theme.primaryColor.toString());
    print(theme.brightness);

    return Scaffold(
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
                      SettingsPage.buildButton(theme, "Starten", Icons.chevron_right_rounded, () => Navigator.of(context).pushNamed(choice == null ? "/setup" : "/home")),
                      const SizedBox(height: 40),

                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              """Hier entsteht die Startseite deiner Notenapp. Bald findest du hier alle wichtigen Infos und Funktionen auf einen Blick.
Schon jetzt kannst du deinen Notendurchschnitt berechnen, Prognosen erstellen und die besten Einbringungen automatisch bestimmen – perfekt abgestimmt auf das neue G9 in Bayern.
Tippe auf Start, um direkt loszulegen.""",
                              style: theme.textTheme.bodySmall
                            ),
                            const Spacer(),
                            Text("© 2025 anweisen", style: theme.textTheme.displayMedium),
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
            color: theme.primaryColor,
            clipBehavior: Clip.hardEdge,
            colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
            width: isWide ? 74 : 50
        ),
        const SizedBox(width: 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("G9 Notenapp",
                style: (isWide ? theme.textTheme.headlineMedium : theme.textTheme.bodyMedium),
                textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false)),
            Text(
              "fürs Abitur in Bayern",
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
