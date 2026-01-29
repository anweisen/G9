import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/hurdles.dart';
import '../logic/types.dart';
import '../logic/results.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/skeleton.dart';
import '../widgets/subpage.dart';
import '../logic/grades.dart';
import 'grade.dart';
import 'hurdles.dart';
import 'switcher.dart';

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
    var underscored = _calculateUnderscoredResults(results);

    var admissionHurdleCheckResults = AdmissionHurdle.check(settings.choice!, results, flags, grades);
    var graduationHurdleCheckResults = GraduationHurdle.check(settings.choice!, results, flags, grades);

    return PageSkeleton(title: const PageTitle(title: "Übersicht"), children: [
      SubpageTrigger(createSubpage: () => const SemesterSwitcherPage(), callback: (result) => {
        if (result is Semester) {
          grades.currentSemester = result
        }
      }, child: _buildTextLine(Row(
        children: [
          Text(grades.currentSemester.detailedDisplay, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12,),
          if (grades.currentSemester != Semester.abi) SubpageTrigger(
              createSubpage: () => GradePage(semester: grades.currentSemester, key: GlobalKey(),),
              callback: (result) {
                if (result is GradeEditResult) {
                  grades.addGrade(result.subject.id, result.entry, semester: result.semester);
                }
              },
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(6)
                  ),
                  child: Icon(Icons.add_rounded, size: 22, color: theme.shadowColor,))
          ),
        ],
      ), [
        Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
        const SizedBox(width: 6),
        Text(GradeHelper.formatNumber(currentSemesterAvg, decimals: 2), style: theme.textTheme.bodyMedium),
        const SizedBox(width: 6),
        Text("(≙ ${GradeHelper.formatNumber(SemesterResult.convertAverage(currentSemesterAvg))})", style: theme.textTheme.bodySmall),
      ])),
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

      const SizedBox(height: 20),

      if (!flags.isEmpty && admissionHurdleCheckResults.isNotEmpty)
        ..._buildHurdleInfo(theme, "Zulassungshürde", admissionHurdleCheckResults)
      else if (!flags.isEmpty && graduationHurdleCheckResults.isNotEmpty)
        ..._buildHurdleInfo(theme, "Anerkennungshürde", graduationHurdleCheckResults),

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
              if (graduationHurdleCheckResults.isNotEmpty || admissionHurdleCheckResults.isNotEmpty) ...[
                Icon(Icons.warning_amber_rounded, size: 14, color: theme.indicatorColor),
                const SizedBox(width: 10),
              ],
              Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
              const SizedBox(width: 4),
              Text(SemesterResult.pointsToAbiGrade(flags.pointsTotal), style: theme.textTheme.bodyMedium),
            ]),
            _buildTextLine(Text("Punkte", style: theme.textTheme.bodyMedium), [
              Text("${flags.pointsTotal}", style: theme.textTheme.bodyMedium),
            ]),
            const SizedBox(height: 4),
            GradeBarChart(points: flags.pointsTotal),
            const SizedBox(height: 15),

            Text("Zulassung", style: theme.textTheme.bodySmall),
            _buildTextLine(Text("Unterpunktungen", style: theme.textTheme.bodyMedium, overflow: TextOverflow.fade), [
              Text("${underscored} / 8", style: theme.textTheme.bodyMedium)
            ]),
            const SizedBox(height: 4),
            _buildHurdleChart(context, underscored),

            if (pastSemestersAvg.isNotEmpty) ...[
              const SizedBox(height: 20),
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
            _buildTextLine(Text("Pflichteinbringungen", style: theme.textTheme.bodyMedium), [
              Text("${flags.forcedSemesters}", style: theme.textTheme.bodyMedium),
            ]),
            if (!flags.isEmpty && stats.bestSubjects.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text("Top ${min(3, stats.bestSubjects.length)} Fächer", style: theme.textTheme.bodySmall),
              for (int i = 0; i < 3 && i < stats.bestSubjects.length; i++)
                _buildTextLine(_buildSubject(theme.textTheme, stats.bestSubjects[i].$1), [
                  Row(children: [
                    for (Semester semester in Semester.values)
                      if (!(results[stats.bestSubjects[i].$1]?[semester]?.prediction ?? true)) Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                        width: 24,
                        height: 20,
                        decoration: (results[stats.bestSubjects[i].$1]?[semester]?.used ?? false) ? BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(4)) : null,
                        child: Center(child: Text(results[stats.bestSubjects[i].$1]?[semester]?.grade.toString() ?? "-",
                          style: (results[stats.bestSubjects[i].$1]?[semester]?.used ?? false ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)?.copyWith(fontSize: 13, fontWeight: FontWeight.bold),)
                        )
                      ),
                  ],),
                  const SizedBox(width: 6),
                  Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
                  const SizedBox(width: 4),
                  Text("${GradeHelper.formatNumber(stats.bestSubjects[i].$2, decimals: 1)}", style: theme.textTheme.bodyMedium),
                ]),
            ]

          ],
        ),
      ),

      if (graduationHurdleCheckResults.isEmpty && admissionHurdleCheckResults.isEmpty)
        ..._buildHurdlePassingInfo(theme),

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
                    Expanded( // Expanded to avoid overflow (Column is no intrinsic width / constraints)
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Halbjahr ${grades.currentSemester.detailedDisplay} abschließen", style: theme.textTheme.displayMedium),
                          Row(
                            children: [
                              Text("zu ${grades.currentSemester.nextSemester().detailedDisplay}", style: theme.textTheme.labelMedium, softWrap: false, overflow: TextOverflow.fade,),
                            ],
                          ),
                        ],
                      ),
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

  List<Widget> _buildHurdleInfo(ThemeData theme, String title, List<HurdleCheckResult> checkResults) {
    return [
      SubpageTrigger(
        createSubpage: () => HurdlesPage(checkResults: checkResults),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.splashColor,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Icon(Icons.gavel_rounded, size: 16, color: theme.textTheme.bodySmall?.color,),
                const SizedBox(width: 4,),
                Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(checkResults.first.hurdle.paragraph, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(checkResults.first.hurdle.desc, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.1)),
            const SizedBox(height: 6),
            Text(checkResults.first.text, style: theme.textTheme.displayMedium),
          ]),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildHurdlePassingInfo(ThemeData theme) {
    return [
      const SizedBox(height: 20),
      SubpageTrigger(
        createSubpage: () => const HurdlesPage(checkResults: []),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.dividerColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, size: 16, color: theme.textTheme.bodySmall?.color,),
                    const SizedBox(width: 5,),
                    Text("Zulassungs- & Anerkennungshürden", style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Alle nötigen Hürden erfüllt", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1)),
              ]),
              Icon(Icons.check_circle_rounded, size: 20, color: theme.primaryColor,),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildTextLine(Widget? front, List<Widget> back) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        front ?? const SizedBox.shrink(),
        Row(verticalDirection: VerticalDirection.down,
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
        double maxWidth = constraints.maxWidth * 0.5;

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

  Widget _buildHurdleChart(BuildContext context, int underscored) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double width = (constraints.maxWidth / 8) - max(4, min(10, constraints.maxWidth * 0.02));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 8; i++)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: (underscored > i ? (underscored >= 6 ? theme.indicatorColor : theme.primaryColor) : theme.hintColor),
                  ),
                  height: 9,
                  width: width,
                ),
            ],
          );
        }
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

  int _calculateUnderscoredResults(Map<Subject, Map<Semester, SemesterResult>> results) {
    int count = 0;

    for (var subjectResults in results.values) {
      for (var semesterResult in subjectResults.values) {
        if (semesterResult.semester == Semester.abi) continue; // nur Q-Phase
        if (!semesterResult.prediction && semesterResult.used && semesterResult.effectiveGrade < 5) {
          count += semesterResult.semester.semesterCountEquivalent;
        }
      }
    }

    return count;
  }
}

class GradeBarChart extends StatefulWidget {
  final int points;

  const GradeBarChart({super.key, required this.points});

  @override
  State<GradeBarChart> createState() => _GradeBarChartState();
}

class _GradeBarChartState extends State<GradeBarChart> {

  bool specific = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          specific = !specific;
        });
      },
      child: specific ? _buildGradeBarSpecific(context, widget.points) : _buildGradeBarTotal(context, widget.points)
    );
  }

  Widget _buildGradeBarSpecific(BuildContext context, int points) {
    final ThemeData theme = Theme.of(context);

    int pointsForBetterGrade = SemesterResult.getMinPointsForBetterAbiGrade(points);
    int pointsForCurrentGrade = SemesterResult.getMinPointsForThisAbiGrade(points);

    String betterGradeText = pointsForBetterGrade == 900 ? "-" : SemesterResult.pointsToAbiGrade(pointsForBetterGrade);
    String currentGradeText = SemesterResult.pointsToAbiGrade(points);
    String worseGradeText = pointsForCurrentGrade <= 300 ? "-" : SemesterResult.pointsToAbiGrade(pointsForCurrentGrade - 1);

    double offset = (points - pointsForCurrentGrade) / (pointsForBetterGrade - pointsForCurrentGrade);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double barWidth = constraints.maxWidth;
          final double segmentOutsideWidth = barWidth * 0.2;
          final double segmentInsideWidth = barWidth - (segmentOutsideWidth * 2);
          final BorderSide border = BorderSide(color: theme.hintColor, width: 2.5);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 22,
                    width: segmentOutsideWidth,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                      // color: theme.shadowColor,
                      border: Border.fromBorderSide(border),
                    ),
                    alignment: Alignment.center,
                    child: Text(betterGradeText, textAlign: TextAlign.center, style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4,),
                  Text("$pointsForBetterGrade", style: theme.textTheme.bodySmall),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 22,
                        width: segmentInsideWidth,
                        decoration: BoxDecoration(
                          color: theme.hintColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(currentGradeText, textAlign: TextAlign.center, style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w600)),
                      ),
                      Transform.translate(
                        offset: Offset(segmentInsideWidth * (1 - offset), -2), // offset = 0 → left, 1 → right(
                        child: Container(
                          height: 24,
                          width: 3,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: Offset(segmentInsideWidth * (1 - offset) - 10, 0), // offset = 0 → left, 1 → right
                    child: Text("$points", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 22,
                    width: segmentOutsideWidth,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                      // color: theme.shadowColor,
                      border: Border.fromBorderSide(border),
                    ),
                    alignment: Alignment.center,
                    child: Text(worseGradeText, textAlign: TextAlign.center, style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4,),
                  Text("$pointsForCurrentGrade", style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          );
        });
  }

  Widget _buildGradeBarTotal(BuildContext context, int points) {
    final ThemeData theme = Theme.of(context);

    double offset = (points - 300) / 600;

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double barWidth = constraints.maxWidth;
          final double segmentZeroWidth = (59 / 600) * barWidth;
          final double segmentWidth = (constraints.maxWidth - segmentZeroWidth) / 3; // 1, 2, 3, (4)
          final BorderSide border = BorderSide(color: theme.hintColor, width: 2.5);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 22,
                            width: segmentZeroWidth,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                              border: Border.fromBorderSide(border),
                              color: (points >= 841 ? theme.hintColor : null),
                              // color: theme.hintColor,
                            ),
                            alignment: Alignment.center,
                            child: Text("0,x", textAlign: TextAlign.center, style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w600)),
                          ),
                          Container(
                            height: 22,
                            width: segmentWidth,
                            decoration: BoxDecoration(
                              border: Border.symmetric(horizontal: border),
                              color: (points < 841 && points >= 661 ? theme.hintColor : null),
                            ),
                            alignment: Alignment.center,
                            child: Text("1,x", textAlign: TextAlign.center, style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w600)),
                          ),
                          Container(
                            height: 22,
                            width: segmentWidth,
                            decoration: BoxDecoration(
                              border: Border(top: border, bottom: border, left: border),
                              color: (points < 661 && points >= 481 ? theme.hintColor : null),
                            ),
                            alignment: Alignment.center,
                            child: Text("2,x", textAlign: TextAlign.center, style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w600)),
                          ),
                          Container(
                            height: 22,
                            width: segmentWidth,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                              border: Border.all(color: theme.hintColor, width: 2.5),
                              color: (points < 481 && points >= 301 ? theme.hintColor : null),
                            ),
                            alignment: Alignment.center,
                            child: Text("3,x", textAlign: TextAlign.center, style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      Transform.translate(
                        offset: Offset(barWidth * (1 - offset), -2), // offset = 0 → left, 1 → right(
                        child: Container(
                          height: 24,
                          width: 3,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      SizedBox(
                        width: barWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("900", style: theme.textTheme.bodySmall),
                            Text("300", style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(barWidth * (1 - offset) - 10, 0), // offset = 0 → left, 1 → right
                        child: Text("$points", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor, height: 1.25, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        });
  }
}

