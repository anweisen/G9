
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

    Map<Semester, double> pastSemestersAvg = {};
    for (Semester semester in Semester.qPhase) {
      var pastSemesterGrades = grades.getGradesForSemester(settings.choice!, semester: semester);
      double avg = GradeHelper.averageOfSubjects(pastSemesterGrades);
      if (avg <= 0) continue; // skip semesters with no grades
      pastSemestersAvg[semester] = avg;
    }
    var betterGradePoints = SemesterResult.getMinPointsForBetterAbiGrade(flags.pointsTotal);

    var (admissionHurdleType, admissionHurdleText) = AdmissionHurdle.check(settings.choice!, results);

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

      if (admissionHurdleType != null && admissionHurdleText != null)...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.splashColor,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Zulassungshürden", style: theme.textTheme.bodySmall),
            Text(admissionHurdleType.desc, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            Text(admissionHurdleText, style: theme.textTheme.displayMedium),
          ]),
        ),
        const SizedBox(height: 30),
      ],

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
            _buildTextLine(Text("Note", style: theme.textTheme.bodyMedium), [
              Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
              const SizedBox(width: 4),
              Text(SemesterResult.pointsToAbiGrade(flags.pointsTotal), style: theme.textTheme.bodyMedium),
            ]),
            _buildTextLine(Text("Punkte", style: theme.textTheme.bodyMedium), [
              Text("${flags.pointsTotal}", style: theme.textTheme.bodyMedium),
            ]),
            if (betterGradePoints != 900)
              _buildTextLine(Text("Bessere Note", style: theme.textTheme.displayMedium), [
                Text("${SemesterResult.pointsToAbiGrade(betterGradePoints)} bei $betterGradePoints", style: theme.textTheme.displayMedium),
              ]),
            if (pastSemestersAvg.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text("Semester", style: theme.textTheme.bodySmall),
              for (var entry in pastSemestersAvg.entries)
                _buildTextLine(Text(entry.key.display, style: theme.textTheme.bodyMedium), [
                  Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
                  const SizedBox(width: 4),
                  Text(GradeHelper.formatNumber(entry.value, decimals: 2), style: theme.textTheme.bodyMedium),
                ]),
            ],
            const SizedBox(height: 15),
            Text("Statistik", style: theme.textTheme.bodySmall),
            _buildTextLine(Text("Notenzahl", style: theme.textTheme.bodyMedium), [
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
        Text(subject.name, style: textTheme.bodyMedium, overflow: TextOverflow.clip, softWrap: false,),
      ],
    );
  }

  Widget _buildChart(BuildContext context, List<MapEntry<int, int>> gradesDistribution) {
    const spacing = 4.0;

    final int maxValue = gradesDistribution.isEmpty ? 1 : gradesDistribution.reduce((a, b) => a.value > b.value ? a : b).value; // find max value for scaling
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
                children: gradesDistribution.map((entry) {
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
                children: gradesDistribution.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: spacing + (16-10)/2),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3.33),
                        color: theme.primaryColor,
                      ),
                      height: 10, // uniform row height
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

  List<MapEntry<int, int>> _calculateSingleGradesDistribution(SettingsDataProvider settings, Map<SubjectId, GradesList> currentSemesterGrades) {
    Map<int, int> gradesDistribution = {};
    for (int i = 0; i <= 15; i++) {
      gradesDistribution[i] = 0; // initialize all grades from 0 to 15
    }

    for (var subject in settings.choice!.subjects) {
      var grades = currentSemesterGrades[subject.id] ?? [];
      for (var grade in grades) {
        gradesDistribution[grade.grade] = (gradesDistribution[grade.grade] ?? 0) + 1;
      }
    }

    // trim bottom to top
    for (int i = 0; i <= 15; i++) {
      if (gradesDistribution[i] != 0) break;
      gradesDistribution.remove(i);
    }
    // trim top to bottom
    for (int i = 15; i >= 0; i--) {
      if (gradesDistribution[i] != 0) break;
      gradesDistribution.remove(i);
    }

    // sort descending
    return gradesDistribution.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }
}
