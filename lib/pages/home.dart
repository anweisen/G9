import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/kmapi.dart';
import '../logic/choice.dart';
import '../logic/grades.dart';
import '../logic/hurdles.dart';
import '../logic/types.dart';
import '../logic/results.dart';
import '../logic/year.dart';
import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/kmapi.dart';
import '../provider/settings.dart';
import '../util/dates.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../widgets/subpage.dart';
import '../widgets/piechart.dart';
import 'account.dart';
import 'bayefg.dart';
import 'change.dart';
import 'grade.dart';
import 'hurdles.dart';
import 'switcher.dart';
import 'oral.dart';
import 'top.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    var settings = Provider.of<SettingsDataProvider>(context);
    var grades = Provider.of<GradesDataProvider>(context);
    var account = Provider.of<AccountDataProvider>(context);

    var results = SemesterResult.calculateResultsWithPredictions(settings.choice!, grades);
    var flags = SemesterResult.applyUseFlags(settings.choice!, results);
    var stats = SemesterResult.calculateStatistics(settings.choice!, results);

    var completed = SemesterResult.isComplete(settings.choice!, results);

    var currentSemesterGrades = grades.getGradesForSemester(settings.choice!);
    var currentSemesterAvg = GradeHelper.averageOfSemester(currentSemesterGrades, grades.currentSemester, settings.choice!);
    var currentSemesterAvgUsed = GradeHelper.averageOfSemesterUsed(results, grades.currentSemester);
    var gradesDistribution = _calculateSingleGradesDistribution(settings, currentSemesterGrades);
    var usedSemesterResults = _flattenUsedResults(results);

    Map<Semester, double> pastSemestersAvg = {};
    Map<Semester, double> pastSemestersAvgUsed = {};
    for (Semester semester in Semester.qPhase) {
      var pastSemesterGrades = grades.getGradesForSemester(settings.choice!, semester: semester);
      double avg = GradeHelper.averageOfSemester(pastSemesterGrades, semester, settings.choice!);
      if (avg > 0) pastSemestersAvg[semester] = avg;
      double avgUsed = GradeHelper.averageOfSemesterUsed(results, semester);
      if (avgUsed > 0) pastSemestersAvgUsed[semester] = avgUsed;
    }

    var admissionHurdleCheckResults = AdmissionHurdle.check(settings.choice!, results, flags, grades);
    var graduationHurdleCheckResults = GraduationHurdle.check(settings.choice!, results, flags, grades);

    var betterChoice = ChangeAbiChoiceResult.getBetterChoiceResult(settings.choice!, flags, grades);

    return PageSkeleton(title: const PageTitle(
        title: "Übersicht",
        crossAxisAlignment: CrossAxisAlignment.center,
        info: AccountWidget(),
    ), children: [
      SubpageTrigger(createSubpage: () => const SemesterSwitcherPage(), callback: (result) => {
        if (result is Semester) {
          grades.changeCurrentSemester(result),
          account.updateSemester(result)
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
                  account.updateSubjectGradesFromResult(result, grades);
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
        ..._buildHurdleInfo(theme, "Zulassungshürde", admissionHurdleCheckResults.first, [...admissionHurdleCheckResults, ...graduationHurdleCheckResults])
      else if (!flags.isEmpty && graduationHurdleCheckResults.isNotEmpty)
        ..._buildHurdleInfo(theme, "Anerkennungshürde", graduationHurdleCheckResults.first, [...admissionHurdleCheckResults, ...graduationHurdleCheckResults]),

      if (grades.currentSemester == Semester.abi) ...[
        if (completed) ...[
          CompletedWidget(flags: flags, noHurdles: admissionHurdleCheckResults.isEmpty && graduationHurdleCheckResults.isEmpty,),
          const SizedBox(height: 20),
        ],
        const AbiDatesWidget(),
        const SizedBox(height: 20),
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
            Text(completed ? "Abitur Ergebnis" : "Abitur Vorhersage", style: theme.textTheme.bodySmall),
            _buildTextLine(Text("Note", style: theme.textTheme.bodyMedium), [
              if (graduationHurdleCheckResults.isNotEmpty || admissionHurdleCheckResults.isNotEmpty) ...[
                Icon(Icons.warning_amber_rounded, size: 14, color: theme.disabledColor),
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
              Text("${flags.underscored} / 8", style: theme.textTheme.bodyMedium)
            ]),
            const SizedBox(height: 4),
            _buildHurdleChart(context, flags.underscored),

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
            _buildTextLine(Text("Einbringungen", style: theme.textTheme.bodyMedium), [
              Text("(≙ ${GradeHelper.formatNumber(SemesterResult.convertAverage(flags.pointsQ / 40))})", style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
              const SizedBox(width: 4),
              Text(GradeHelper.formatNumber(flags.pointsQ / 40, decimals: 2), style: theme.textTheme.bodyMedium),
            ]),
            if (grades.currentSemester == Semester.abi) _buildTextLine(Text("Abiprüfungen", style: theme.textTheme.bodyMedium), [
              Text("(≙ ${GradeHelper.formatNumber(SemesterResult.convertAverage(flags.pointsAbi / 20))})", style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
              const SizedBox(width: 4),
              Text(GradeHelper.formatNumber(flags.pointsAbi / 20, decimals: 2), style: theme.textTheme.bodyMedium),
            ]),
            if (!flags.isEmpty && stats.bestSubjects.isNotEmpty) SubpageTrigger(
              createSubpage: () => TopSubjectsSubpage(stats: stats, results: results),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 15),
                Text("Top ${min(3, stats.bestSubjects.length)} Fächer", style: theme.textTheme.bodySmall),
                for (int i = 0; i < 3 && i < stats.bestSubjects.length; i++)
                  _buildTextLine(_buildSubject(theme.textTheme, stats.bestSubjects[i].$1), [
                    if (MediaQuery.of(context).size.width > 500) Row(children: [
                      for (Semester semester in Semester.values)
                        if (results[stats.bestSubjects[i].$1]?[semester]?.valid ?? false) Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                          width: 21,
                          height: 19,
                          decoration: (results[stats.bestSubjects[i].$1]?[semester]?.used ?? false) ? BoxDecoration(color: theme.hintColor, borderRadius: BorderRadius.circular(4)) : null,
                          child: Center(child: Text(results[stats.bestSubjects[i].$1]?[semester]?.effectiveGrade.toString() ?? "-",
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center,)
                        )
                      ),
                    ]),
                    const SizedBox(width: 8),
                    Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
                    const SizedBox(width: 4),
                    Text(GradeHelper.formatNumber(stats.bestSubjects[i].$2, decimals: 1), style: theme.textTheme.bodyMedium),
                  ]),
              ]),
            ),
          ]
        )
      ),

      ..._buildImproveAbiChoice(theme, betterChoice, settings.choice!, flags),

      if (graduationHurdleCheckResults.isEmpty && admissionHurdleCheckResults.isEmpty)
        ..._buildHurdlePassingInfoAndBayEfg(theme, completed, settings.choice!, results, flags, grades),

      if (!flags.isEmpty) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.dividerColor,
          ),
          child: GradesPieChart(grades: grades.getAllGrades(), results: usedSemesterResults),
        ),
      ],

      const SizedBox(height: 20),
      HomeSemesterSwitchButtons(
        btn1: grades.currentSemester != Semester.abi ? GestureDetector(
            onTap: () {
              final result = grades.currentSemester.nextSemester();
              grades.changeCurrentSemester(result);
              account.updateSemester(result);
              context.push("/home"); // reload completely ( not replace/go/pushReplacement )
            },
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: theme.primaryColor),
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8, left: 18, right: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible( // Expanded to avoid overflow (Column is no intrinsic width / constraints)
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Halbjahr ${grades.currentSemester.detailedDisplay} abschließen", style: theme.textTheme.displayMedium),
                          Text("zu ${grades.currentSemester.nextSemester().display}", style: theme.textTheme.labelMedium, softWrap: false, overflow: TextOverflow.fade,),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: theme.textTheme.labelMedium?.color, size: 24,),
                  ],
                ),
              ),
            ),
          ) : null,
          btn2: grades.currentSemester != Semester.q12_1 ? GestureDetector(
            onTap: () {
              final result = grades.currentSemester.previousSemester();
              grades.changeCurrentSemester(result);
              account.updateSemester(result);
              context.push("/home"); // reload completely ( not replace/go/pushReplacement )
            },
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor, width: 4)),
              child: Padding(
                padding: const EdgeInsets.only(top: 14 - 4, bottom: 8 - 4, left: 18 - 4, right: 18 - 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible( // Expanded to avoid overflow (Column is no intrinsic width / constraints)
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("zurück", style: theme.textTheme.displayMedium),
                          Text("zu ${grades.currentSemester.previousSemester().display}", style: theme.textTheme.bodyMedium, softWrap: false, overflow: TextOverflow.fade,),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ) : null
      )

    ]);
  }

  List<Widget> _buildHurdleInfo(ThemeData theme, String title, HurdleCheckResult show, List<HurdleCheckResult> checkResults) {
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

  List<Widget> _buildHurdlePassingInfoAndBayEfg(ThemeData theme, bool completed, Choice choice, Map<Subject, Map<Semester, SemesterResult>> result, ResultsFlags flags, GradesDataProvider provider) {
    List<HurdleCheckResult> bayEfgHurdles = BayEfgHurdle.check(choice, result, flags, provider);
    bool passedQ = bayEfgHurdles.isEmpty || !bayEfgHurdles.any((hurdle) => !(hurdle.hurdle as BayEfgHurdle).finalCheckAfterAbi);

    return [
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.dividerColor,
        ),
        child: Column(
          children: [
            SubpageTrigger(
              createSubpage: () => const HurdlesPage(checkResults: []),
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
            const SizedBox(height: 15),
            SubpageTrigger(
              createSubpage: () => BayEfgHurdlePage(checkResults: bayEfgHurdles),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_circle_up_rounded, size: 16, color: theme.textTheme.bodySmall?.color,),
                        const SizedBox(width: 5,),
                        Text("Auswahlhürden Förderung BayEFG", style: theme.textTheme.bodySmall?.copyWith(height: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (completed) ...[
                      if (bayEfgHurdles.isEmpty) Text("Alle Hürden erfüllt", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1))
                      else Text("Hürden nicht erfüllt", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1)),
                    ] else ...[
                      if (passedQ) Text("Vorauswahlhürden erfüllt", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1))
                      else Text("Hürden vermutlich nicht erfüllt", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1)),
                    ],
                  ]),
                  if (completed && bayEfgHurdles.isEmpty) Icon(Icons.check_circle_rounded, size: 20, color: theme.primaryColor,)
                  else if (!completed && passedQ) Icon(Icons.check_circle_outline_rounded, size: 20, color: theme.primaryColor,)
                  else Icon(Icons.info_outline_rounded, size: 20, color: theme.primaryColor,)
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildImproveAbiChoice(ThemeData theme, ChangeAbiChoiceResult? betterChoice, Choice currentChoice, ResultsFlags currentFlags) {
    final pointsDifference = betterChoice != null ? betterChoice.flags.pointsTotal - currentFlags.pointsTotal : 0;
    final changedPair = ChangeAbiChoiceResult.findChangedAbiSubjects(currentChoice, betterChoice?.choice);
    return [
      const SizedBox(height: 20),
      SubpageTrigger(
        createSubpage: () => const ChangeAbiSubpage(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.dividerColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 17, color: theme.textTheme.bodySmall?.color,),
                    const SizedBox(width: 3,),
                    Text("Abiturwahl verbessern", style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                if (betterChoice == null)
                  Text("Bereits bestmögliche Wahl", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1))
                else ... [
                  SmallSubjectWidget(subject: changedPair!.$1, old: true, choice: currentChoice),
                  SmallSubjectWidget(subject: changedPair.$2, old: false, choice: betterChoice.choice),
                ],
              ]),
              if (betterChoice == null)
                Icon(Icons.info_outline_rounded, size: 20, color: theme.primaryColor,)
              else Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${betterChoice.flags.pointsTotal}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text("${pointsDifference >= 0 ? "+" : ""}$pointsDifference",
                      style: theme.textTheme.displayMedium?.copyWith(fontSize: 14, color: pointsDifference > 0 ? theme.indicatorColor : pointsDifference < 0 ? theme.disabledColor : theme.primaryColor)),
                ],
              ),
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
    return Expanded(
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: subject.color),
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(subject.name, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,)),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<MapEntry<int, int>> gradesDistribution) {
    const spacing = 3.0;

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
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 30,
                          child: Text("${(entry.value / totalGrades * 100).round()}%", textAlign: TextAlign.end, style: theme.textTheme.bodySmall)),
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
                    color: (underscored > i ? (underscored >= 6 ? theme.disabledColor : theme.primaryColor) : theme.hintColor),
                  ),
                  height: 9,
                  width: width,
                ),
            ],
          );
        }
    );
  }

  List<SemesterResult> _flattenUsedResults(Map<Subject, Map<Semester, SemesterResult>> results) {
    List<SemesterResult> usedResults = [];
    for (var subjectResults in results.values) {
      for (var semesterResult in subjectResults.values) {
        if (semesterResult.used && !semesterResult.prediction) {
          usedResults.add(semesterResult);
        }
      }
    }
    return usedResults;
  }

  List<MapEntry<int, int>> _calculateSingleGradesDistribution(SettingsDataProvider settings, Map<SubjectId, GradesList> currentSemesterGrades) {
    Map<int, int> gradesDistribution = {};
    for (int i = 0; i <= 15; i++) {
      gradesDistribution[i] = 0; // initialize all grades from 0 to 15
    }

    for (var subject in settings.choice!.subjects) {
      var grades = currentSemesterGrades[subject.id] ?? [];
      for (var grade in grades) {
        if (grade.type.area == GradeTypeArea.flag) continue;
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

    // (points more than needed for current) / (points width between current and better)
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

class HomeSemesterSwitchButtons extends StatelessWidget {
  const HomeSemesterSwitchButtons({super.key, this.btn1, this.btn2});

  final Widget? btn1;
  final Widget? btn2;

  @override
  Widget build(BuildContext context) {
    if (btn1 == null && btn2 == null) {
      return const SizedBox.shrink();
    }

    bool wide = MediaQuery.of(context).size.width > 360;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (btn2 != null && btn1 != null && !wide)
            Flexible(flex: 4, child: btn1!)
          else if (btn1 != null)
            Expanded(child: btn1!),

          if (wide && btn1 != null && btn2 != null)
            const SizedBox(width: 16),

          if (wide)
            if (btn2 != null && btn1 == null)
              Expanded(child: btn2!,)
            else if (btn1 != null)
              IntrinsicWidth(child: btn2),
        ],
      ),
    );
  }
}

class AccountWidget extends StatelessWidget {
  const AccountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = Provider.of<AccountDataProvider>(context);
    return Flexible(
      fit: FlexFit.loose,
      child: GestureDetector(
        onTap: account.isLoggedIn ? () => SubpageController.of(context).openSubpage(const AccountPage()) : () => Api.doGoogleLoginAndSync(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: theme.dividerColor.withOpacity(0.66),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (account.isLoggedIn) ...[
                Flexible(child: Text(account.userProfile!.name, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, softWrap: true, maxLines: 1,)),
                const SizedBox(width: 6,),
                ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(account.userProfile!.picture, width:22, height: 22, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle_rounded, size: 18))
                ),
              ] else ...[
                const Icon(Icons.account_circle_rounded, size: 18),
                const SizedBox(width: 8,),
                Text("Login", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class CompletedWidget extends StatelessWidget {
  const CompletedWidget({super.key, required this.flags, required this.noHurdles});

  final ResultsFlags flags;
  final bool noHurdles;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.dividerColor,
        ),
        child: Column(
          children: [
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                noHurdles ? Flexible(
                  child: Row(
                    spacing: 12,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 28, color: noHurdles ? theme.indicatorColor : theme.disabledColor,),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Herzlichen Glückwunsch", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.indicatorColor), softWrap: true,),
                            Text("zum bestanden Abitur", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600), softWrap: true,),
                          ],
                        ),
                      ),
                    ],
                  ),
                ) : Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tut uns leid", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), softWrap: true,),
                      Text("Hürden nicht alle überwunden", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.disabledColor), softWrap: true,),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: noHurdles ? theme.primaryColor : theme.splashColor,
                  ),
                  child: noHurdles ? Column(
                    children: [
                      Text(SemesterResult.pointsToAbiGrade(flags.pointsTotal), style: theme.textTheme.headlineMedium?.copyWith(color: theme.scaffoldBackgroundColor)),
                      Text("${flags.pointsTotal}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.scaffoldBackgroundColor)),
                    ],
                  ) : Column(
                    children: [
                      Icon(Icons.cancel_outlined, size: 28, color: theme.disabledColor),
                      const SizedBox(height: 5,),
                      Text("${flags.pointsTotal}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.primaryColor)),
                    ],
                  ),
                )
              ],
            )
          ],
        )
    );
  }
}


class AbiDatesWidget extends StatelessWidget {
  const AbiDatesWidget({super.key});

  bool _shouldShowOralWeek(Choice choice, List<Subject> sortedOralExamSubjects, OralAbiExamWeek week, Map<SubjectId, SubjectSettings>? subjectSettings) {
    if (sortedOralExamSubjects.length >= 2) return false;
    if (subjectSettings == null) return true;
    if (!choice.hasSelectedExamTypes) return true;
    for (Subject oralSubject in choice.oralAbiSubjects) {
      var settings = subjectSettings[oralSubject.id];
      if (settings?.oralExamDate == null || settings == null) continue;
      if (DateHelper.isWithinDateSpan(week.startDate, week.endDate, settings.oralExamDate!)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var kmapi = Provider.of<KmApiProvider>(context);
    var settings = Provider.of<SettingsDataProvider>(context);
    var data = Provider.of<GradesDataProvider>(context);
    var choice = settings.choice!;

    Map<Subject, List<Semester>> missingGrades = SemesterResult.getIncompleteSubjects(choice, data);

    int predictedGraduationYear = YearHelper.extractGraduationYear(data);
    kmapi.fetchDataIfNotPresent(predictedGraduationYear);

    List<Subject> sortedOralSubjects = choice.oralAbiSubjects
        .where((e) => settings.subjectSettings?[e.id]?.oralExamDate != null).toList()..sort((a, b) {
      var aDate = settings.subjectSettings?[a.id]?.oralExamDate;
      var bDate = settings.subjectSettings?[b.id]?.oralExamDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    List<(Subject, WrittenAbiExamDate)>? sortedWrittenDates;
    int completedCount = 0, todayIndex = -1;
    if (kmapi.abiDates != null) {
      var mappedWrittenDates = KmApi.mapSubjectsToWrittenExamDates(kmapi.abiDates!.writtenExamDates, choice.hasSelectedExamTypes ? choice.writtenAbiSubjects : choice.abiSubjects, choice);
      sortedWrittenDates = KmApi.sortWittenAbiExamDates(mappedWrittenDates);

      for (var writtenDate in sortedWrittenDates) {
        if (DateHelper.isDateToday(writtenDate.$2.date)) todayIndex = completedCount;
        if (!DateHelper.isDatePassed(writtenDate.$2.date)) break;
        completedCount++;
      }
      for (var oralDate in kmapi.abiDates!.oralExamWeeks) {
        if (!_shouldShowOralWeek(choice, sortedOralSubjects, oralDate, settings.subjectSettings)) {
          continue;
        }
        if (DateHelper.isDateSpanToday(oralDate.startDate, oralDate.endDate)) todayIndex = completedCount;
        if (!DateHelper.isDatePassed(oralDate.endDate)) break;
        completedCount++;
      }
      for (var oralSubject in sortedOralSubjects) {
        var oralDate = settings.subjectSettings![oralSubject.id]!.oralExamDate!;
        if (DateHelper.isDateToday(oralDate)) todayIndex = completedCount;
        if (!DateHelper.isDatePassed(oralDate)) break;
        completedCount++;
      }
    }

    final double width = MediaQuery.of(context).size.width;
    final bool useDateAbbreviations = width < 450 && width > 380 || width < 340;

    return SubpageTrigger(
      createSubpage: () => OralExamTypeSelectorPage(choice: choice, initialSubjectSettings: settings.subjectSettings, key: GlobalKey()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.dividerColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 1,
          children: [
            if (!choice.hasSelectedExamTypes) ... [
              Container(
                decoration: BoxDecoration(
                  color: theme.shadowColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 22, color: theme.shadowColor,),
                    const SizedBox(width: 10,),
                    Flexible(child: Text("Mündliche/Schriftliche Prüfungen festlegen", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: theme.shadowColor), maxLines: 5, softWrap: true, overflow: TextOverflow.ellipsis,)),
                  ],
                ),
              ),
              const SizedBox(height: 10,),
            ] else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth = constraints.maxWidth;
                  double width = min((maxWidth - 48) / 5 - 8, 60);
                  return SizedBox(
                    width: maxWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            for (int i = 0; i < 5; i++)
                              ColorFadeContainer.create(
                                enabled: i == todayIndex,
                                width: width,
                                height: 9,
                                colorFrom: theme.primaryColor,
                                colorTo: theme.indicatorColor,
                                duration: const Duration(milliseconds: 750),
                                decoration: BoxDecoration(
                                  color: i < completedCount ? theme.indicatorColor : theme.hintColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                            ),
                          ],
                        ),
                        Text("$completedCount / 5", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.primaryColor),),
                      ],
                    ),
                  );
                }
              ),
              const SizedBox(height: 10,),
            ],

            Text("Schriftliche Prüfungen", style: theme.textTheme.bodySmall),
            const SizedBox(height: 2,),
            if (sortedWrittenDates != null) ...[
              for (var (index, writtenDate) in sortedWrittenDates.indexed)
                _buildSubjectExamDateLine(
                    subject: writtenDate.$1, date: writtenDate.$2.date, choice: settings.choice!, index: index,
                    completedIndex: completedCount, currentIndex: todayIndex, theme: theme, useDateAbbreviations: useDateAbbreviations
                ),
            ] else DotLoadingIndicator(style: theme.textTheme.bodyMedium!, duration: const Duration(milliseconds: 1500),),

            const SizedBox(height: 10,),

            Text("Mündliche Prüfungen", style: theme.textTheme.bodySmall),
            const SizedBox(height: 2,),
            if (kmapi.abiDates != null) ...[
              for (var (index, oralSubject) in sortedOralSubjects.indexed)
                _buildSubjectExamDateLine(
                    subject: oralSubject, date: settings.subjectSettings![oralSubject.id]!.oralExamDate!, choice: choice, index: index + 3,
                    completedIndex: completedCount, currentIndex: todayIndex, theme: theme, useDateAbbreviations: useDateAbbreviations
                ),
              for (var oralDate in kmapi.abiDates!.oralExamWeeks)
                if (_shouldShowOralWeek(choice, sortedOralSubjects, oralDate, settings.subjectSettings)) Row(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text("${oralDate.weekNumber}. Woche", style: SmallSubjectWidget.getTextStyle(theme, DateHelper.isDatePassed(oralDate.endDate))),
                          ShimmerContainer.create(
                            enabled: DateHelper.isDateSpanToday(oralDate.startDate, oralDate.endDate) || max(oralDate.startDate.difference(DateTime.now()).inDays, 0) <= 1,
                            shimmerColor: theme.primaryColor,
                            duration: const Duration(milliseconds: 1500),
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: theme.shadowColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)),
                                child: Text(DateHelper.formatWeekDifference(oralDate.startDate, oralDate.endDate, useAbbreviations: useDateAbbreviations),
                                    style: theme.textTheme.displayMedium?.copyWith(height: 0, fontWeight: FontWeight.w600))
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(DateHelper.formatWeek(oralDate.startDate, oralDate.endDate)),
                  ],
                ),
            ] else DotLoadingIndicator(style: theme.textTheme.bodyMedium!, duration: const Duration(milliseconds: 1500),),

            if (completedCount >= 5) ...[
              const SizedBox(height: 10,),
              Text("Zeugnisvergabe", style: theme.textTheme.bodySmall),
              if (kmapi.abiDates != null) ...[
                Text("ab ${kmapi.abiDates!.graduationDate.formattedDate}", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16, color: theme.primaryColor), softWrap: true,),
              ] else  DotLoadingIndicator(style: theme.textTheme.bodyMedium!, duration: const Duration(milliseconds: 1500),),

              const SizedBox(height: 10,),
              Text("Trage noch folgende Noten ein", style: theme.textTheme.bodySmall),
              const SizedBox(height: 4,),
              Row(
                spacing: 10,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: theme.disabledColor,),
                  Flexible(
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 2,
                      children: [
                        for (var missingEntry in missingGrades.entries)
                          Row(
                            spacing: 6,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(missingEntry.key.name,
                                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 16, color: theme.primaryColor, fontWeight: FontWeight.w600, height: 1.4),
                                  overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,
                                ),
                              ),
                              for (var semester in missingEntry.value)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(color: theme.splashColor, borderRadius: BorderRadius.circular(5)),
                                  child: Text(semester.name.toUpperCase(), style: theme.textTheme.displayMedium?.copyWith(height: 0, fontWeight: FontWeight.w600, color: theme.disabledColor))
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ]
              )
            ]
          ]
        ),
      ),
    );
  }

  Widget _buildSubjectExamDateLine({
    required Subject subject, required DateTime date, required Choice choice, required int index,
    required int completedIndex, required int currentIndex, required ThemeData theme, required bool useDateAbbreviations
  }) {
    return Row(
      spacing: 16,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              SmallSubjectWidget(subject: subject, old: DateHelper.isDatePassed(date), choice: choice,),
              ShimmerContainer.create(
                enabled: !DateHelper.isDatePassed(date) && index == completedIndex,
                // enabled: DateHelper.isDateToday(date) || max(date.difference(DateTime.now()).inDays, 0) <= 1,
                shimmerColor: theme.primaryColor,
                duration: const Duration(milliseconds: 1500),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: theme.shadowColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)),
                    child: Text(DateHelper.formatDateDifference(date, useAbbreviations: useDateAbbreviations),
                        style: theme.textTheme.displayMedium?.copyWith(height: 0, fontWeight: FontWeight.w600))
                ),
              ),
            ],
          ),
        ),
        Text(DateHelper.formatDate(date, useRelative: false)),
      ],
    );
  }
}




