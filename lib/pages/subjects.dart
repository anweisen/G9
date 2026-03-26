import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/grades.dart';
import '../logic/results.dart';
import '../provider/grades.dart';
import '../provider/account.dart';
import '../provider/settings.dart';
import '../widgets/skeleton.dart';
import '../logic/types.dart';
import '../widgets/subpage.dart';
import 'subject.dart';
import 'switcher.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final settings = Provider.of<SettingsDataProvider>(context);
    final gradesProvider = Provider.of<GradesDataProvider>(context);
    final accountProvider = Provider.of<AccountDataProvider>(context, listen: false);
    final semester = gradesProvider.currentSemester;
    final grades = gradesProvider.getGradesForSemester(settings.choice!, semester: semester);
    final average = GradeHelper.averageOfSemester(grades, semester, settings.choice!);
    final subjects = settings.choice?.subjectsToDisplayForSemester(semester);

    print("Building subjects page with choice: ${settings.choice}");

    return PageSkeleton(
        title: SubpageTrigger(
            createSubpage: () => const SemesterSwitcherPage(),
            callback: (result) => {
              if (result != null && result is Semester) {
                gradesProvider.changeCurrentSemester(result),
                accountProvider.updateSemester(result)
              }
            },
            child: PageTitle(
              title: "Fächer  ${semester.display}",
              info: Row(
                  verticalDirection: VerticalDirection.down,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text("Ø", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w300, fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(GradeHelper.formatNumber(average, decimals: 2), style: theme.textTheme.headlineMedium),
                    const SizedBox(width: 8),
                    Text("(≙ ${GradeHelper.formatNumber(SemesterResult.convertAverage(average))})", style: theme.textTheme.bodySmall),
                  ]
                )),
        ),
        children: [
          for (Subject subject in subjects!)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SubjectWidget(subject: subject, choice: settings.choice!, semester: Semester.mapSemesterToDisplaySemester(semester, subject.category)),
            )
        ]);
  }
}

class SubjectWidget extends StatelessWidget {
  final Subject subject;
  final Semester semester;
  final Choice choice;

  const SubjectWidget({super.key, required this.subject, required this.semester, required this.choice});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final grades = Provider.of<GradesDataProvider>(context).getGrades(subject.id, semester: semester); // sorted!

    final Color contrastColor = subject.color.computeLuminance() > 0.78 ? (theme.brightness == Brightness.light ? Colors.black : Colors.black87) : Colors.white;

    return GestureDetector(
      onTap: () => SubpageController.of(context).openSubpage(SubjectPage(subject: subject, key: GlobalKey(),)),
      child: Container(
        decoration: BoxDecoration(
          color: subject.color.withAlpha(theme.brightness == Brightness.dark ? 150 : 166),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(16, 7, 8, 7),
        child: Row(
          children: [
            Stack(
                alignment: Alignment.center,
                children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: subject.color,
                ),
                width: 36,
                height: 22,
              ),
              Center(child: Text(GradeHelper.formatNumber(GradeHelper.average(subject, semester, choice, grades) / semester.semesterCountEquivalent), style: TextStyle(color: contrastColor, fontSize: 13, fontWeight: FontWeight.w500))),
            ]),
            const SizedBox(width: 10),
            Text(subject.name, style: theme.textTheme.labelMedium?.copyWith(color: contrastColor), maxLines: 1, overflow: TextOverflow.clip),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
