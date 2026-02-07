import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/grades.dart';
import '../logic/types.dart';
import '../widgets/chart.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';

class GradesDevelopmentPage extends StatelessWidget {
  const GradesDevelopmentPage({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final choice = Provider.of<SettingsDataProvider>(context).choice;
    final dataProvider = Provider.of<GradesDataProvider>(context);

    final semesters = choice!.getSemestersForSubject(subject);
    final rawGrades = dataProvider.getRawGrades();

    List<GradeEntry> grades = [];
    List<Semester> gradesSemesters = [];
    for (Semester semester in semesters) {
      final semesterGrades = rawGrades[semester]?[subject.id] ?? [];
      semesterGrades.sort((a, b) => a.date.compareTo(b.date),);
      grades.addAll(semesterGrades);
      gradesSemesters.addAll(List.filled(semesterGrades.length, semester));
    }

    final avg = GradeHelper.unweightedAverageOf(grades);

    return SubpageSkeleton(
      title: Row(
        children: [
          SubjectPageTitle(subject: subject),
        ],
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text("Notenentwicklung", softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 1, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 12),
            Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
            const SizedBox(width: 6),
            Text(GradeHelper.formatNumber(avg, decimals: 2), style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 12,),
        SubjectGradesChart(grades: grades, gradesSemesters: gradesSemesters)
      ],
    );
  }
}
