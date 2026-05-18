import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../widgets/subpage.dart';
import 'account.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {

  Map<Semester, bool> deleteGradesForSemester = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = Provider.of<AccountDataProvider>(context);
    final settings = Provider.of<SettingsDataProvider>(context);
    final grades = Provider.of<GradesDataProvider>(context);

    return SubpageSkeleton(
      title: const PageTitle(title: "Daten zurücksetzen"),
      children: [
        Text("Hier kannst du alle lokal gespeicherten Daten zurücksetzen. Um deinen Account und mitsamt jeglichen Daten von unseren Servern zu löschen wähle \"Account löschen\". Diese Aktionen sind unwiderruflich. ", style: theme.textTheme.displayMedium),
        const SizedBox(height: 24,),

        Text("Lösche zuerst deine Accountdaten", style: theme.textTheme.bodySmall),
        const SizedBox(height: 6,),
        if (account.isLoggedIn) ...[
          Wrap(
            children: [
              ActionButton(
                text: "Account löschen",
                icon: Icons.delete_rounded,
                textColor: theme.disabledColor,
                backgroundColor: theme.splashColor,
                borderColor: theme.splashColor,
                onTap: null,
                createSubpage: () => const ConfirmDeleteAccountDialogePage(),
              ),
            ],
          )
        ] else ...[
          Text("Du bist mit keinem Account eingeloggt", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1)),
        ],

        const SizedBox(height: 25,),
        Text("Lösche eingetragene Noten", style: theme.textTheme.bodySmall),
        const SizedBox(height: 6,),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (Semester semester in Semester.values)
              GestureDetector(
                onTap: () => setState(() => deleteGradesForSemester[semester] = !(deleteGradesForSemester[semester] ?? false)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: deleteGradesForSemester[semester] == true ? theme.shadowColor : theme.dividerColor, width: 2)
                  ),
                  child: Text(semester.display, style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15, height: 0, color: deleteGradesForSemester[semester] == true ? theme.primaryColor : theme.shadowColor)),
                ),
              )
          ],
        ),
        const SizedBox(height: 8,),
        Wrap(
          children: [
            ActionButton(
              text: "Noten löschen",
              icon: Icons.delete_rounded,
              textColor: deleteGradesForSemester.values.any((value) => value) ? theme.primaryColor : theme.shadowColor,
              backgroundColor: null,
              borderColor: theme.dividerColor,
              onTap: null,
              createSubpage: deleteGradesForSemester.values.any((value) => value) ? () => ConfirmActionDialogePage(
                title: "Noten löschen",
                confirmText: "Diese Noten löschen",
                confirmIcon: Icons.delete_rounded,
                description: "Bist du sicher, dass du die Noten der ausgewählten Semester (${deleteGradesForSemester.keys.where((semester) => deleteGradesForSemester[semester] == true).map((semester) => semester.display).join(", ")}) löschen möchtest? Diese Aktion ist unwiderruflich.",
                onConfirm: (context) {
                  for (Semester semester in deleteGradesForSemester.keys) {
                    if (deleteGradesForSemester[semester] == true) {
                      grades.clearSemesterGrades(semester);
                    }
                  }
                },
              ) : null,
            ),
          ],
        ),

        const SizedBox(height: 25,),
        Text("Lösche eingetragene Abiturvorhersagen", style: theme.textTheme.bodySmall),
        const SizedBox(height: 6,),
        Wrap(
          children: [
            ActionButton(
              text: "Abi Vorhersagen löschen",
              icon: Icons.delete_rounded,
              textColor: grades.abiPredictions?.isEmpty ?? true ? theme.shadowColor : theme.primaryColor,
              backgroundColor: null,
              borderColor: theme.dividerColor,
              onTap: null,
              createSubpage: grades.abiPredictions?.isNotEmpty ?? false ? () => ConfirmActionDialogePage(
                title: "Vorhersagen löschen",
                confirmText: "Abi Vorhersagen löschen",
                confirmIcon: Icons.delete_rounded,
                description: "Bist du sicher, dass du deine eingetragenen Abiturprüfungsvorhersagen löschen möchtest? Diese Aktion ist unwiderruflich.",
                onConfirm: (context) {
                  grades.clearAllAbiPredictions();
                },
              ) : null,
            ),
          ],
        ),

        const SizedBox(height: 25,),

        Text("Lösche alle lokalen Daten", style: theme.textTheme.bodySmall),
        const SizedBox(height: 6,),
        Wrap(
          children: [
            ActionButton(
              text: "Alle Daten zurücksetzen",
              icon: Icons.delete_forever_rounded,
              textColor: theme.disabledColor,
              backgroundColor: theme.splashColor,
              borderColor: theme.splashColor,
              onTap: null,
              createSubpage: () => ConfirmActionDialogePage(
                title: "Daten zurücksetzen",
                confirmText: "Alle Daten löschen",
                confirmIcon: Icons.delete_forever_rounded,
                description: "Bist du sicher, dass du deinen lokalen Daten löschen möchtest? Diese Aktion ist unwiderruflich.",
                onConfirm: (context) {
                  grades.clearAllData();
                  settings.clearAllData();
                  account.clearStash();
                  account.notifyListeners();
                  context.go("/welcome");
                }
              ),
            ),
          ],
        )

      ],
    );
  }
}

