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
import '../widgets/general.dart';
import '../widgets/subpage.dart';
import 'subject.dart';
import 'switcher.dart';
import 'order.dart';

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
    final subjects = settings.getOrderedSubjects(semester);

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
            title: "Fächer",
            crossAxisAlignment: CrossAxisAlignment.center,
            titleSuffix: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.shadowColor.withValues(alpha: 0.15), width: 2)
              ),
              child: Text(semester.display.toUpperCase(), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: theme.shadowColor,)),
            ),
            info: Row(
              verticalDirection: VerticalDirection.down,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text("Ø", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w400, fontSize: 22)),
                const SizedBox(width: 8),
                Text(GradeHelper.formatNumber(average, decimals: 2), style: theme.textTheme.headlineMedium),
                const SizedBox(width: 8),
                Text("(≙ ${GradeHelper.formatNumber(SemesterResult.convertAverage(average))})", style: theme.textTheme.bodySmall),
              ]
            )
          ),
        ),
        children: [
          for (Subject subject in subjects!)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SubjectWidget(subject: subject, choice: settings.choice!, semester: Semester.mapSemesterToDisplaySemester(semester, subject.category)),
            ),

          const SizedBox(height: 26),
          SubpageTrigger(
            createSubpage: () => SubjectOrderPage(initialSubjectSettings: settings.subjectSettings, key: GlobalKey(),),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Fächerreihenfolge und -darstellung ändern", style: theme.textTheme.bodySmall),
                const SizedBox(height: 5),
                ActionButton(
                  text: "Fächerpräferenzen anpassen",
                  icon: Icons.reorder_rounded,
                  textColor: theme.primaryColor,
                  backgroundColor: null,
                  borderColor: theme.dividerColor,
                  onTap: null,
                ),
              ],
            ),
          ),
        ]
    );
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
          gradient: LinearGradient(
            colors: [
              subject.color.withValues(alpha: theme.brightness == Brightness.dark ? 0.52 : 0.62),
              subject.color.withValues(alpha: theme.brightness == Brightness.dark ? 0.62 : 0.72),
            ],
            stops: const [ 0.0, 0.66 ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                  width: 37,
                  height: 22,
                ),
                Center(child: Text(GradeHelper.formatNumber(GradeHelper.average(subject, semester, choice, grades) / semester.semesterCountEquivalent, allowZero: true), style: TextStyle(color: contrastColor, fontSize: 13, fontWeight: FontWeight.w600))),
              ]
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(subject.name, style: theme.textTheme.labelMedium?.copyWith(color: contrastColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Icon(Icons.chevron_right_rounded, color: contrastColor, size: 24),
          ],
        ),
      ),
    );
  }
}
