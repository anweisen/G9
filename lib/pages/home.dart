import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/hurdles.dart';
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
    var currentSemesterAvg = GradeHelper.averageOfSubjects(currentSemesterGrades, semester: grades.currentSemester);
    var currentSemesterAvgUsed = GradeHelper.averageOfSemesterUsed(results, grades.currentSemester);
    var gradesDistribution = _calculateSingleGradesDistribution(settings, currentSemesterGrades);

    Map<Semester, double> pastSemestersAvg = {};
    Map<Semester, double> pastSemestersAvgUsed = {};
    for (Semester semester in Semester.qPhase) {
      var pastSemesterGrades = grades.getGradesForSemester(settings.choice!, semester: semester);
      double avg = GradeHelper.averageOfSubjects(pastSemesterGrades);
      if (avg > 0) pastSemestersAvg[semester] = avg;
      double avgUsed = GradeHelper.averageOfSemesterUsed(results, semester);
      if (avgUsed > 0) pastSemestersAvgUsed[semester] = avgUsed;
    }
    var betterGradePoints = SemesterResult.getMinPointsForBetterAbiGrade(flags.pointsTotal);

    var (admissionHurdleType, admissionHurdleText) = AdmissionHurdle.check(settings.choice!, results, grades);
    var (graduationHurdleType, graduationHurdleText) = GraduationHurdle.check(settings.choice!, results, flags, grades);

    return PageSkeleton(title: const PageTitle(title: "Übersicht"), children: [
      _buildTextLine(Text(grades.currentSemester.detailedDisplay, style: theme.textTheme.bodyMedium), [
        Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
        const SizedBox(width: 6),
        Text(GradeHelper.formatNumber(currentSemesterAvg, decimals: 2), style: theme.textTheme.bodyMedium),
        const SizedBox(width: 6),
        Text("(≙ ${GradeHelper.formatNumber(SemesterResult.convertAverage(currentSemesterAvg))})", style: theme.textTheme.bodySmall),
      ]),
      if (grades.currentSemester != Semester.abi) _buildTextLine(null, [
        Text("Einbringungen", style: theme.textTheme.bodySmall),
        const SizedBox(width: 6),
        Text("Ø", style: theme.textTheme.displayMedium),
        const SizedBox(width: 3),
        Text(GradeHelper.formatNumber(currentSemesterAvgUsed, decimals: 2), style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 3),
        Text("(≙ ${GradeHelper.formatNumber(SemesterResult.convertAverage(currentSemesterAvgUsed))})", style: theme.textTheme.bodySmall),
      ]),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        child: _buildChart(context, gradesDistribution),
      ),
      const SizedBox(height: 36),

      if (!flags.isEmpty && admissionHurdleType != null && admissionHurdleText != null)
        ..._buildHurdleInfo(theme, "Zulassungshürde", admissionHurdleType.paragraph, admissionHurdleType.desc, admissionHurdleText)
      else if (!flags.isEmpty && graduationHurdleType != null && graduationHurdleText != null)
        ..._buildHurdleInfo(theme, "Anerkennungshürde", graduationHurdleType.paragraph, graduationHurdleType.desc, graduationHurdleText),

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
            if (betterGradePoints < 823)
              _buildTextLine(Text("Bessere Note", style: theme.textTheme.displayMedium), [
                Text("${SemesterResult.pointsToAbiGrade(betterGradePoints)} bei $betterGradePoints", style: theme.textTheme.displayMedium),
              ]),
            if (pastSemestersAvg.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text("Semester", style: theme.textTheme.bodySmall),
              for (var entry in pastSemestersAvg.entries) ...[
                _buildTextLine(Text(entry.key.display, style: theme.textTheme.bodyMedium), [
                  Text("Ø", style: theme.textTheme.displayMedium),
                  const SizedBox(width: 2),
                  Text(GradeHelper.formatNumber(pastSemestersAvgUsed[entry.key] ?? 0, decimals: 2), style: theme.textTheme.displayMedium),
                  const SizedBox(width: 2),
                  Text("(≙ ${GradeHelper.formatNumber(SemesterResult.convertAverage(pastSemestersAvgUsed[entry.key] ?? 0))})", style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
                  const SizedBox(width: 4),
                  Text(GradeHelper.formatNumber(entry.value, decimals: 2), style: theme.textTheme.bodyMedium),
                ]),
              ]
            ],
            const SizedBox(height: 15),
            Text("Statistik", style: theme.textTheme.bodySmall),
            _buildTextLine(Text("Notenzahl", style: theme.textTheme.bodyMedium), [
              Text("${stats.numberGrades}", style: theme.textTheme.bodyMedium),
            ]),
            if (!flags.isEmpty && stats.bestSubjects.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text("Top ${min(5, stats.bestSubjects.length)} Fächer", style: theme.textTheme.bodySmall),
              for (int i = 0; i < 5 && i < stats.bestSubjects.length; i++)
                _buildTextLine(_buildSubject(theme.textTheme, stats.bestSubjects[i].$1), [
                  Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
                  const SizedBox(width: 4),
                  Text("${GradeHelper.formatNumber(stats.bestSubjects[i].$2, decimals: 2)}", style: theme.textTheme.bodyMedium),
                ]),
            ]

          ],
        ),
      ),

      const SizedBox(height: 30),

      if (grades.currentSemester != Semester.abi)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              grades.currentSemester = grades.currentSemester.nextSemester();
              Navigator.popAndPushNamed(context, "/home");
            },
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: theme.primaryColor),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Halbjahr ${grades.currentSemester.detailedDisplay} abschließen", style: theme.textTheme.displayMedium),
                        Text("Als nächstes: ${grades.currentSemester.nextSemester().detailedDisplay}", style: theme.textTheme.labelMedium),
                      ],
                    ),
                    Icon(Icons.chevron_right_rounded, color: theme.textTheme.labelMedium?.color),
                  ],
                ),
              ),
            ),
          ),
        )
    ]);
  }

  List<Widget> _buildHurdleInfo(ThemeData theme, String title, String paragraph, String desc, String text) {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.splashColor,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.bodySmall),
          Text(paragraph, style: theme.textTheme.bodySmall),
          Text(desc, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          Text(text, style: theme.textTheme.displayMedium),
        ]),
      ),
      const SizedBox(height: 30),
    ];
  }

  Widget _buildTextLine(Widget? front, List<Widget> back) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        front ?? const SizedBox.shrink(),
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
    final int totalGrades = gradesDistribution.fold(0, (sum, entry) => sum + entry.value); // total number of grades
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double maxWidth = constraints.maxWidth * 0.6;

        return Row(
          children: [
            // left column (fixed width for consistent alignment)
            SizedBox(
              width: 84, // <-- fixed width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: gradesDistribution.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: spacing),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 20, // <-- fixed width
                            child: Text("${entry.key}", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1, fontSize: 16))),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 22,
                          child: Text("${entry.value}x", textAlign: TextAlign.end, style: theme.textTheme.displayMedium)),
                        const SizedBox(width: 6),
                        Text("${(entry.value / totalGrades * 100).round()}%", style: theme.textTheme.bodySmall),
                      ],
                    ),
                )).toList(),
              ),
            ),
            const SizedBox(width: 8), // space between columns
            // right column (flexible width)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: gradesDistribution.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: spacing + (16-10)/2),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3.33),
                        color: theme.primaryColor,
                      ),
                      height: 10, // uniform row height
                      width: maxValue > 0 ? (entry.value / maxValue) * maxWidth : 0, // percentage-based width
                  )
                )).toList(),
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
