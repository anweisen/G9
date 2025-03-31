import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/types.dart';
import '../logic/results.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/skeleton.dart';
import '../logic/grades.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    var settings = Provider.of<SettingsDataProvider>(context);
    var grades = Provider.of<GradesDataProvider>(context);

    var results = SemesterResult.calculateResultsWithPredictions(settings.choice!, grades);
    var flags = SemesterResult.applyUseFlags(settings.choice!, results);
    var stats = SemesterResult.calculateStatistics(settings.choice!, results);

    var currentSemesterGrades = grades.getGradesForSemester(settings.choice!);
    var currentSemesterAvg = GradeHelper.averageOfSubjects(currentSemesterGrades);
    var gradesDistribution = _calculateSingleGradesDistribution(settings, currentSemesterGrades);

    return PageSkeleton(title: const PageTitle(title: "Übersicht"), children: [

      _buildTextLine(Text("Q${grades.currentSemester.display}", style: theme.textTheme.bodyMedium), [
        Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
        const SizedBox(width: 6),
        Text(GradeHelper.formatNumber(currentSemesterAvg, decimals: 2), style: theme.textTheme.bodyMedium),
        const SizedBox(width: 6),
        Text("(${GradeHelper.formatNumber(SemesterResult.convertAverage(currentSemesterAvg))})", style: theme.textTheme.bodySmall),
      ]),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        child: _buildChart(context, gradesDistribution),
      ),
      const SizedBox(height: 36),

      // Abitur Vorhersage
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.dividerColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Abitur Vorhersage", style: theme.textTheme.bodySmall),
            _buildTextLine(Text("Note", style: theme.textTheme.labelSmall), [
              Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
              const SizedBox(width: 4),
              Text(SemesterResult.pointsToAbiGrade(flags.pointsTotal), style: theme.textTheme.bodyMedium),
            ]),
            _buildTextLine(Text("Punkte", style: theme.textTheme.labelSmall), [
              Text("${flags.pointsTotal}", style: theme.textTheme.bodyMedium),
            ]),
            const SizedBox(height: 15),
            Text("Statistik", style: theme.textTheme.bodySmall),
            _buildTextLine(Text("Notenzahl", style: theme.textTheme.labelSmall), [
              Text("${stats.numberGrades}", style: theme.textTheme.bodyMedium),
            ]),
            const SizedBox(height: 15),
            Text("Bestes Fach", style: theme.textTheme.bodySmall),
            _buildTextLine(_buildSubject(theme.textTheme, stats.bestSubject), [
              Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
              const SizedBox(width: 4),
              Text("${GradeHelper.formatNumber(stats.bestSubjectAvg, decimals: 2)}", style: theme.textTheme.bodyMedium),
            ]),

          ],
        ),
      ),
    ]);
  }

  Widget _buildTextLine(Widget front, List<Widget> back) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        front,
        Row(
            verticalDirection: VerticalDirection.down,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: back)
      ],
    );
  }

  Widget _buildSubject(TextTheme textTheme, Subject subject) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: subject.color),
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 8),
        Text(subject.name, style: textTheme.labelSmall, overflow: TextOverflow.clip, softWrap: false,),
      ],
    );
  }

  Widget _buildChart(BuildContext context, Map<int, int> gradesDistribution) {
    const spacing = 4.0;

    final int maxValue = gradesDistribution.values.isEmpty ? 1 : gradesDistribution.values.reduce((a, b) => a > b ? a : b); // find max value for scaling
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double maxWidth = constraints.maxWidth * 0.6;

        return Row(
          children: [
            // left column (fixed width for consistent alignment)
            SizedBox(
              width: 80, // <-- fixed width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: gradesDistribution.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: spacing),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 20, // <-- fixed width
                            child: Text("${entry.key}", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1, fontSize: 16))),
                        const SizedBox(width: 4),
                        Text("${entry.value}x", style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 8), // space between columns
            // right column (flexible width)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: gradesDistribution.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: spacing + (16-12)/2),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: theme.primaryColor,
                      ),
                      height: 12, // uniform row height
                      width: maxValue > 0 ? (entry.value / maxValue) * maxWidth : 0, // percentage-based width
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<int, int> _calculateSingleGradesDistribution(SettingsDataProvider settings, Map<SubjectId, GradesList> currentSemesterGrades) {
    Map<int, int> gradesDistribution = {};
    for (var subject in settings.choice!.subjects) {
      var grades = currentSemesterGrades[subject.id] ?? [];
      for (var grade in grades) {
        gradesDistribution[grade.grade] = (gradesDistribution[grade.grade] ?? 0) + 1;
      }
    }
    return gradesDistribution;
  }
}
