import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import '../logic/choice.dart';
import '../logic/results.dart';
import '../logic/year.dart';
import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../pdf/pdf_widget.dart';
import '../widgets/subpage.dart';
import '../widgets/skeleton.dart';
import 'account.dart';
import 'change.dart';
import 'extra.dart';
import 'setup.dart';
import 'top.dart';
import 'oral.dart';
import 'order.dart';
import 'reset.dart';
import 'vk.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final accountProvider = Provider.of<AccountDataProvider>(context);
    final gradesProvider = Provider.of<GradesDataProvider>(context);
    final settingsProvider = Provider.of<SettingsDataProvider>(context);

    Choice? choice = settingsProvider.choice;
    int predictedGraduationYear = YearHelper.extractGraduationYear(gradesProvider);

    return PageSkeleton(
        title: const PageTitle(title: "Präferenzen"),
        children: [
          const SizedBox(height: 8),

          if (accountProvider.isLoggedIn)
            SubpageTrigger(
              createSubpage: () => const AccountPage(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.dividerColor,
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(accountProvider.userProfile!.picture, width: 48, height: 48, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle_rounded, size: 44))
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
                      child: Icon(Icons.logout_rounded, size: 24, color: theme.disabledColor,)
                    )
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => Api.doGoogleLoginAndSync(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.dividerColor,
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_circle_rounded, size: 46, color: theme.shadowColor,),
                        const SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 6,
                          children: [
                            Text("mit Google", style: theme.textTheme.bodySmall),
                            Text("anmelden", style: theme.textTheme.bodyMedium?.copyWith(height: 1)),
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

          if (choice != null) SetupFinishPage.buildSubjectsGrid(choice, theme),

          // subjects list contains section spacing
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Abiturjahrgang", style: theme.textTheme.bodySmall),
              const SizedBox(height: 1),
              Text(YearHelper.formatClassOfYear(predictedGraduationYear), style: theme.textTheme.bodyMedium),
            ],
          ),

          const SizedBox(height: 20),
          buildButtonLayout((context) => [
            buildButton(theme, "Wahl ändern", Icons.settings_backup_restore_rounded, () => context.push("/setup"), small: true),
            buildButton(theme, "Abifächer ändern", Icons.published_with_changes_rounded, () => context.push("/setup/abi"), small: true),
          ]),
          const SizedBox(height: 10),
          buildButtonLayout((context) => [
            buildButton(theme, "Prüfungsarten festlegen", Icons.tune_rounded, SubpageTrigger.onTap(context, () => OralExamTypeSelectorPage(choice: choice!, initialSubjectSettings: settingsProvider.subjectSettings, key: GlobalKey())), small: true),
            buildButton(theme, "Vertiefungskurs tauschen", Icons.merge_type_rounded, SubpageTrigger.onTap(context, () => const ChangeVkPage()), small: true),
          ]),
          const SizedBox(height: 10),
          buildButtonLayout((context) => [
            buildButton(theme, "Abiwahl verbessern", Icons.swap_horiz_rounded, SubpageTrigger.onTap(context, () => const ChangeAbiSubpage()), small: true),
            buildButton(theme, "Nachprüfungsempfehlungen", Icons.arrow_circle_up_rounded, SubpageTrigger.onTap(context, () => const ExtraExamPage()), small: true),
          ]),
          const SizedBox(height: 10),
          buildButtonLayout((context) => [
            buildButton(theme, "Beste Fächer", Icons.star_rounded, SubpageTrigger.onTap(context, () {
              final results = SemesterResult.calculateResultsWithPredictions(choice!, gradesProvider);
              final _ = SemesterResult.applyUseFlags(choice, results);
              return TopSubjectsSubpage(choice: choice, results: results);
            }), small: true),
            buildButton(theme, "Fächerreihenfolge, -darstellung", Icons.reorder_rounded, SubpageTrigger.onTap(context, () => SubjectOrderPage(initialSubjectSettings: settingsProvider.subjectSettings, key: GlobalKey(),)), small: true),
          ]),
          const SizedBox(height: 10),
          buildButtonLayout((context) => [
            buildButton(theme, "Zur Startseite", Icons.info_outline_rounded, () => context.go("/welcome"), small: true),
            buildButton(theme, "OpenSource auf GitHub", Icons.code_rounded, () async {
              const url = "https://github.com/anweisen/G9";
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            }, small: true),
          ]),
          const SizedBox(height: 10),
          buildButtonLayout((context) => [
            buildButton(theme, "Notenübersicht drucken", Icons.print_rounded, SubpageTrigger.onTap(context, () => const PdfPreviewPage()), small: true),
          ]),
          const SizedBox(height: 10),
          buildButtonLayout((context) => [
            buildButton(theme, "Daten zurücksetzen", Icons.delete_forever_rounded, iconSize: 20, SubpageTrigger.onTap(context, () => const ResetPage()), small: true, danger: true),
          ]),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: UnauthorizedPageSkeleton.buildFooter(theme, context)
          ),
        ]);
  }

  static Widget buildButtonLayout(List<Widget> Function(BuildContext context) buttonsBuilder) {
    return LayoutBuilder(
      builder: (context, constraints) {
        List<Widget> buttons = buttonsBuilder(context);
        const spacing = 12.0;
        const minButtonWidth = 240.0;
        final minButtonWidthSum = minButtonWidth * buttons.length + spacing * (buttons.length - 1);
        final buttonWidth = constraints.maxWidth >= minButtonWidthSum ? (constraints.maxWidth - spacing * (buttons.length - 1)) / buttons.length : constraints.maxWidth;
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (Widget button in buttons)
              SizedBox(width: buttonWidth, child: button),
          ],
        );
      }
    );
  }

  static Widget buildButton(ThemeData theme, String text, IconData icon, Function()? onTap, {bool primary = true, bool small = false, double? iconSize, bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 15 : 18, vertical: small ? 7 : 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(small ? 8 : 10),
          color: small ? null : danger ? theme.splashColor : primary ? theme.primaryColor : theme.dividerColor,
          border: small ? Border.all(color: theme.dividerColor, width: 2) : null,
        ),
        child: Row(
          spacing: 12,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: small ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
          textDirection: small ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Expanded(child: Text(text, style: (primary ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)
                ?.copyWith(fontSize: small ? 17 : null, color: danger ? theme.disabledColor : small ? (primary ? theme.primaryColor : theme.shadowColor) : null), overflow: TextOverflow.ellipsis, maxLines: 1, softWrap: true,)),
            SizedBox(width: 18, child: Icon(icon, color: danger ? theme.disabledColor : small ? (primary ? theme.primaryColor : theme.shadowColor) : (primary ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)?.color, size: iconSize ?? 18)),
          ],
        ),
      ),
    );
  }
}
