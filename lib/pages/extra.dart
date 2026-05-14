import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'tendency.dart';
import '../api/kmapi.dart';
import '../logic/choice.dart';
import '../logic/types.dart';
import '../logic/grades.dart';
import '../logic/hurdles.dart';
import '../logic/results.dart';
import '../widgets/skeleton.dart';
import '../widgets/subjects.dart';
import '../widgets/subpage.dart';
import '../provider/grades.dart';
import '../provider/kmapi.dart';
import '../provider/settings.dart';

class ExtraExamPage extends StatelessWidget {
  const ExtraExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dataProvider = Provider.of<GradesDataProvider>(context);
    final kmapiProvider = Provider.of<KmApiProvider>(context);
    final settingsProvider = Provider.of<SettingsDataProvider>(context);

    ExtraExamDate? examDate = kmapiProvider.abiDates?.extraExamDate;

    List<ExtraExamOptionResult> options = ExtraExamOptionResult.getExtraExamSubjectOptions(settingsProvider.choice!, dataProvider);

    List<ExtraExamOptionResult> mandatoryOptions = options.where((option) => option.mandatory).toList();
    List<ExtraExamOptionResult> voluntaryImprovementOptions = options.where((option) => !option.mandatory && option.improvement).toList();
    List<ExtraExamOptionResult> otherOptions = options.where((option) => !option.mandatory && !option.improvement).toList();
    int otherOptionsTotalDelta = otherOptions.fold(0, (sum, option) => sum + option.deltaPoints);
    int bestPossibleTotal = options.first.newPointsTotal - options.first.deltaPoints + otherOptionsTotalDelta;

    return SubpageSkeleton(
      title: const PageTitle(title: "Nachprüfungen"),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Spätestens bis ${examDate?.formattedDate}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.shadowColor, height: 0)),
              const SizedBox(height: 4),
              Text("Mündliche Zusatzprüfungen sind nur in schriftlichen Abiturfächern möglich", style: theme.textTheme.displayMedium?.copyWith(height: 0)),
              const SizedBox(height: 4),
              Text("Beachte die Anmeldefrist (i.d.R. Schultag nach Bekanntgabe schriftlicher Ergebnisse)", style: theme.textTheme.displayMedium?.copyWith(color: theme.disabledColor, height: 0)),
            ],
          )
        ),

        const SizedBox(height: 28),

        Text("Verpflichtende Zusatzprüfung zum Bestehen", style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        if (mandatoryOptions.isEmpty) ...[
          Text("Keine verpflichtenden Nachprüfungen erforderlich", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1)),
        ] else for (ExtraExamOptionResult option in mandatoryOptions) ...[
          ..._buildOption(theme, option, settingsProvider.choice!, dataProvider),
          const SizedBox(height: 12),
        ],

        if (voluntaryImprovementOptions.isNotEmpty || mandatoryOptions.isEmpty) ...[
          const SizedBox(height: 28),

          Text("Freiwillige Zusatzprüfungen zum Verbessern", style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          for (ExtraExamOptionResult option in voluntaryImprovementOptions) ...[
            ..._buildOption(theme, option, settingsProvider.choice!, dataProvider),
            const SizedBox(height: 12),
          ],
          if (voluntaryImprovementOptions.isEmpty)
            Text("Keine realistischen Möglichkeiten zur Verbesserung durch eine Nachprüfung", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1)),
        ],

        if (otherOptions.isNotEmpty) ...[
          const SizedBox(height: 28),

          Text("Freiwillige Zusatzprüfungen", style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          for (ExtraExamOptionResult option in otherOptions) ...[
            ..._buildOption(theme, option, settingsProvider.choice!, dataProvider),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8,),

          Container(
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bestmögliches Ergebnis (15 P. in allen Zusatzprüfungen)", style: theme.textTheme.bodySmall),

                const SizedBox(height: 10,),

                Row(
                  spacing: 24,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("$bestPossibleTotal", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text("+$otherOptionsTotalDelta", style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: theme.indicatorColor)),
                      ],
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Text("Ø ${SemesterResult.pointsToAbiGrade(bestPossibleTotal - otherOptionsTotalDelta)}",
                            style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, height: 0, decoration: TextDecoration.lineThrough, decorationColor: theme.shadowColor, decorationThickness: 2,)),
                        Center(child: Icon(Icons.keyboard_double_arrow_right_rounded, size: 18, color: theme.shadowColor,)),
                        Text("Ø ${SemesterResult.pointsToAbiGrade(bestPossibleTotal)}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, height: 0)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),

        ]
      ],
    );
  }

  List<Widget> _buildOption(ThemeData theme, ExtraExamOptionResult option, Choice choice, GradesDataProvider dataProvider) {
    return [
      Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MediumSubjectWidget(subject: option.subject),
          Container(
            decoration: BoxDecoration(
              color: option.mandatory ? theme.splashColor : theme.dividerColor,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Text("${(option.mandatory || option.improvement) ? "mindestens " : ""}${option.requiredGrade} P. in Nachprüfung",
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 14, height: 0, color: option.mandatory ? theme.disabledColor : theme.shadowColor)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      SubpageTrigger(
        createSubpage: () => GradesTendencyPage(subject: option.subject, semester: Semester.abi, choice: choice, gradesProvider: dataProvider, grades: dataProvider.getGrades(option.subject.id, semester: Semester.abi)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: option.mandatory ? theme.splashColor : theme.dividerColor, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (GradeEntry entry in option.grades)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Flexible(child: Text(entry.type.name, style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.shadowColor, fontSize: 14,), softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(entry.grade.toString(), style: theme.textTheme.displayMedium?.copyWith(height: 1.6, fontWeight: FontWeight.w600, color: (entry.type == GradeType.zusatz) ? theme.primaryColor : theme.shadowColor, fontSize: 14)),
                        )
                      ],
                    ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Flexible(child: Text("Verrechnetes Ergebnis", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.shadowColor, fontSize: 14,), softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(GradeHelper.formatNumber(GradeHelper.average(option.subject, Semester.abi, choice, option.grades) / 4, allowZero: true, decimals: 1),
                            style: theme.textTheme.displayMedium?.copyWith(height: 1.6, fontWeight: FontWeight.w600, color: theme.primaryColor, fontSize: 14)),
                      )
                    ],
                  ),
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool wrapped = constraints.maxWidth < 470;
                  return Container(
                    padding: wrapped ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12) : null,
                    decoration: BoxDecoration(
                      color: wrapped ? theme.dividerColor : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 14,
                      mainAxisSize: wrapped ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Ø ${SemesterResult.pointsToAbiGrade(option.newPointsTotal)}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text("Ø ${SemesterResult.pointsToAbiGrade(option.newPointsTotal - option.deltaPoints)}", style: theme.textTheme.displayMedium?.copyWith(
                              fontSize: 13, color: theme.shadowColor, decoration: TextDecoration.lineThrough, decorationColor: theme.shadowColor, decorationThickness: 2,
                            )),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${option.pointsSubjectAfter}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text("${option.pointsSubjectBefore}", style: theme.textTheme.displayMedium?.copyWith(
                              fontSize: 13, color: theme.shadowColor, decoration: TextDecoration.lineThrough, decorationColor: theme.shadowColor, decorationThickness: 2,
                            )),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${option.newPointsTotal}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text("+${option.deltaPoints}", style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: theme.indicatorColor)),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              )
            ],
          ),
        ),
      ),
    ];
  }

}

class ExtraExamOptionResult {

  final bool mandatory;
  final bool improvement;
  final Subject subject;
  final int requiredGrade;
  final GradesList grades;
  final int pointsSubjectBefore;
  final int pointsSubjectAfter;
  final int deltaPoints;
  final int newPointsTotal;

  const ExtraExamOptionResult(this.mandatory, this.improvement, this.subject, this.requiredGrade, this.grades, this.pointsSubjectBefore, this.pointsSubjectAfter, this.newPointsTotal) : deltaPoints = pointsSubjectAfter - pointsSubjectBefore;

  static List<ExtraExamOptionResult> getExtraExamSubjectOptions(Choice choice, GradesDataProvider dataProvider) {
    // TODO multiple exams may be required to meet hurdles

    Map<Subject, Map<Semester, SemesterResult>> results = SemesterResult.calculateResultsWithPredictions(choice, dataProvider);
    ResultsFlags flags = SemesterResult.applyUseFlags(choice, results);
    // Zulassungshürden müssen nicht mehr geprüft werden, mussten ja bereits erreicht werden
    List<HurdleCheckResult> graduationHurdles = GraduationHurdle.check(choice, results, flags, dataProvider);
    bool mandatory = graduationHurdles.isNotEmpty; // Verpflichtende Nachprüfung um Anerkennungshürde zu erreichen

    double previousAbiGrade = SemesterResult.pointsToAbiGradeDouble(flags.pointsTotal) ?? 4.0;

    List<ExtraExamOptionResult> options = [];

    // Nachprüfung nur in schriftlichen Abiturfächern möglich
    for (Subject writtenSubject in choice.writtenAbiSubjects) {
      GradesList grades = dataProvider.getGrades(writtenSubject.id, semester: Semester.abi);
      if (grades.isEmpty) {
        // Noch keine schriftliche Prüfung eingetragen: nutze Prognose
        int? enteredPrediction = dataProvider.getAbiPrediction(writtenSubject.id);
        int calculatedPrediction = SemesterResult.calculatePrediction(writtenSubject, results);
        grades = [GradeEntry(enteredPrediction ?? calculatedPrediction, GradeType.schriftlich, DateTime.now())];
      }

      // Zusatzprüfung nicht mehr möglich (bereits eingetragen / schriftliche Prüfung noch nicht eingetragen)
      if (!GradeType.zusatz.stillPossible(grades.map((entry) => entry.type).toList())) continue;

      int currentPoints = GradeHelper.result(writtenSubject, Semester.abi, choice, grades);

      // Finde niedrigste erforderliche Note in der Zusatzprüfung in diesem Fach
      bool added = false;
      for (int grade = grades.first.grade; grade <= 15; grade++) {

        List<GradeEntry> gradesWithExam = [...grades, GradeEntry(grade, GradeType.zusatz, DateTime.now())];
        int resultPoints = GradeHelper.result(writtenSubject, Semester.abi, choice, gradesWithExam);
        SemesterResult newSemesterResult = SemesterResult(resultPoints, gradesWithExam.length, Semester.abi);

        Map<Subject, Map<Semester, SemesterResult>> newResults = Map.of(results);
        // also copy inner map, otherwise we would modify the original results which would cause issues when checking multiple grades
        Map<Semester, SemesterResult> newSubjectResults = Map.of(newResults[writtenSubject] ?? {});
        newSubjectResults[Semester.abi] = newSemesterResult;
        newResults[writtenSubject] = newSubjectResults;

        // calling applyUseFlags again on used results yields incorrect data
        ResultsFlags newFlags = ResultsFlags(flags.forcedSemesters, flags.pointsQ, flags.pointsAbi - currentPoints + resultPoints, flags.underscored, flags.isEmpty);
        List<HurdleCheckResult> newGraduationHurdles = GraduationHurdle.check(choice, newResults, newFlags, dataProvider);
        double newAbiGrade = SemesterResult.pointsToAbiGradeDouble(newFlags.pointsTotal) ?? 4.0;

        if (!added && ((mandatory && newGraduationHurdles.isEmpty) || (!mandatory && newAbiGrade < previousAbiGrade) )) {
          options.add(ExtraExamOptionResult(mandatory, true, writtenSubject, grade, gradesWithExam, currentPoints, resultPoints, newFlags.pointsTotal));
          added = true;
        } else if (grade == 15) {
          // Keine Verbesserung möglich, aber trotzdem Option zur freiwilligen Prüfung anbieten
          options.add(ExtraExamOptionResult(false, false, writtenSubject, grade, gradesWithExam, currentPoints, resultPoints, newFlags.pointsTotal));
          break;
        }

      }
    }
    options.sort((a, b) {
      int compare = a.requiredGrade.compareTo(b.requiredGrade);
      if (compare != 0) return compare;
      return b.deltaPoints.compareTo(a.deltaPoints);
    });
    return options;
  }

}
