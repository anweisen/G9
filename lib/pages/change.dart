import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/hurdles.dart';
import '../logic/results.dart';
import '../logic/types.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import 'settings.dart';

class ChangeAbiSubpage extends StatefulWidget {
  const ChangeAbiSubpage({super.key});

  @override
  State<ChangeAbiSubpage> createState() => _ChangeAbiSubpageState();
}

class _ChangeAbiSubpageState extends State<ChangeAbiSubpage> {

  bool _applyAbiPredictions = true;

  void _toggleApplyAbiPredictions() {
    setState(() {
      _applyAbiPredictions = !_applyAbiPredictions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final gradesProvider = Provider.of<GradesDataProvider>(context);
    final choice = Provider.of<SettingsDataProvider>(context).choice;

    final currentResult = ChangeAbiChoiceResult.createChoiceResult(choice!, gradesProvider, applyAbiPredictions: _applyAbiPredictions);
    final choices = ChangeAbiChoiceResult.getSortedChoiceResultsForAbi(choice, gradesProvider, applyAbiPredictions: _applyAbiPredictions);

    return SubpageSkeleton(
      title: const Row(
        children: [
          PageTitle(title: "Abifächer umwählen"),
        ],
      ),
      children: [
        Text("Aktuelle Abiturprüfungsfächer", style: theme.textTheme.bodySmall),
        const SizedBox(height: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: choice.abiSubjects.map((subject) => Column(
            children: [
              SmallSubjectWidget(subject: subject, old: false, choice: choice,),
              const SizedBox(height: 3),
            ],
          )).toList()
        ),

        if (gradesProvider.abiPredictions?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8,),
          GestureDetector(
            onTap: _toggleApplyAbiPredictions,
            child: Row(
              children: [
                Icon(_applyAbiPredictions ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 18, color: _applyAbiPredictions ? theme.disabledColor : theme.shadowColor,),
                const SizedBox(width: 10),
                Flexible(child: Text("Eingetragene Abiturvorhersagen in den aktuell gewählten Fächern haben maßgeblichen Einfluss auf die Berechnung der prognostizierten Leistungen und ihre Differenzen",
                    style: theme.textTheme.bodySmall?.copyWith(color: _applyAbiPredictions ? theme.disabledColor : theme.shadowColor,))
                ),
              ],
            ),
          ),
          AnimatedDrawerTransition(
            expanded: _applyAbiPredictions,
            duration: const Duration(milliseconds: 500),
            margin: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const SizedBox(width: 18 + 8,),
                Flexible(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (MapEntry<SubjectId, int> entry in gradesProvider.abiPredictions!.entries)
                        if (gradesProvider.getGrades(entry.key, semester: Semester.abi).isEmpty) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(Subject.byId[entry.key]!.name, style: theme.textTheme.bodySmall?.copyWith(height: 1.25)),
                              const SizedBox(width: 6),
                              Text(entry.value.toString(), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, height: 1.25)),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],

        for (ChangeAbiChoiceResult choiceResult in choices) ...[
          const SizedBox(height: 16),
          ChangeAbiChoiceResultWidget(modifiedResult: choiceResult, originalResult: currentResult,),
        ],

        const SizedBox(height: 36,),

        SettingsPage.buildButton(theme, "Abifächer ändern", Icons.published_with_changes_rounded, () => Navigator.pushNamed(context, "/setup/abi")),

      ]);
  }
}

class ChangeAbiChoiceResult {
  final Choice choice;
  final Map<Subject, Map<Semester, SemesterResult>> results;
  final ResultsFlags flags;
  final List<HurdleCheckResult> hurdles;

  ChangeAbiChoiceResult(this.choice, this.results, this.flags, this.hurdles);

  static ChangeAbiChoiceResult? getBetterChoiceResult(Choice currentChoice, ResultsFlags currentResultFlags, GradesDataProvider gradesProvider) {
    List<ChangeAbiChoiceResult> results = getSortedChoiceResultsForAbi(currentChoice, gradesProvider);
    if (results.isEmpty) return null;
    if (results.first.flags.pointsTotal > currentResultFlags.pointsTotal) return results.first;
    return null;
  }

  static List<ChangeAbiChoiceResult> getSortedChoiceResultsForAbi(Choice currentChoice, GradesDataProvider gradesProvider, {applyAbiPredictions = true}) {
    List<ChangeAbiChoiceResult> results = getChoiceResultsForSubstitution(currentChoice, gradesProvider, applyAbiPredictions: applyAbiPredictions)
        + getChoiceResultsForAbi4(currentChoice, gradesProvider, applyAbiPredictions: applyAbiPredictions)
        + getChoiceResultsForAbi5(currentChoice, gradesProvider, applyAbiPredictions: applyAbiPredictions);
    results.sort((a, b) {
      if (a.hurdles.isEmpty && b.hurdles.isNotEmpty) return -1;
      if (a.hurdles.isNotEmpty && b.hurdles.isEmpty) return 1;
      if (a.flags.underscored != b.flags.underscored) return a.flags.underscored.compareTo(b.flags.underscored);
      return b.flags.pointsTotal.compareTo(a.flags.pointsTotal);
    });
    return results;
  }

  static List<ChangeAbiChoiceResult> getChoiceResultsForSubstitution(Choice choice, GradesDataProvider gradesProvider, {applyAbiPredictions = true}) {
    // Für abi4 ist in diesen beiden fällen immer eine Gesellschaftswissenschaft verpflichtend (da Substitution nur bei NTG/SG-LK möglich ist)
    // daher ändern sich die Beschränkungen für abi4 nicht, in abi5 kann nun ein weiteres Fach gewählt werden (bei Mathe muss eine Fremdsprache gewählt werden)
    ChoiceOptions optionsMathe = ChoiceHelper.getSubMatheOptions(ChoiceBuilder.fromChoice(choice));
    if (!optionsMathe.isEmpty) {
      bool changedSub = !choice.substituteMathe;
      ChoiceBuilder changedBuilder = ChoiceBuilder.fromChoice(choice)..substituteMathe = changedSub;
      return getChoiceResultsForAbi5(changedBuilder.build(), gradesProvider, includeSame: true, applyAbiPredictions: applyAbiPredictions);
    }
    ChoiceOptions optionsDeutsch = ChoiceHelper.getSubDeutschOptions(ChoiceBuilder.fromChoice(choice));
    if (!optionsDeutsch.isEmpty) {
      bool changedSub = !choice.substituteDeutsch;
      ChoiceBuilder changedBuilder = ChoiceBuilder.fromChoice(choice)..substituteDeutsch = changedSub;
      return getChoiceResultsForAbi5(changedBuilder.build(), gradesProvider, includeSame: true, applyAbiPredictions: applyAbiPredictions);
    }
    return [];
  }

  static List<ChangeAbiChoiceResult> getChoiceResultsForAbi4(Choice choice, GradesDataProvider gradesProvider, {includeSame = false, applyAbiPredictions = true}) {
    ChoiceOptions options = ChoiceHelper.getAbi4Options(ChoiceBuilder.fromChoice(choice));
    // Sonderfall: Wenn für abi5 keine Beschränkungen bestehen kann für abi4 die Möglichkeit bestehen das selbe Fach zu wählen was derzeit
    //             für abi5 gewählt ist, da die Optionen/Beschränkungen in der gesetzen Reihenfolge geprüft werden (und somit im Nachhinein die Wahl für abi5 eingeschränkt werden würde, und dieses Fach für abi5 rausfallen würde)
    //             Dieser effektive Tausch von abi4/abi5 hat jedoch keinen Einfluss auf das Ergebnis, und wird somit in diesem Sonderfall übersprungen, ohne die Beschränkungen für abi5 neu zu berechnen.
    //             In der initialen Wahl (auf die ChoiceHelper ausgelegt ist) kann dieser Sonderfall nicht auftreten, da die Schritte und deren Beschränkungen nacheinander berechnet werden.
    return options.subjects.where((subject) => subject != choice.abi5 && (includeSame || subject != choice.abi4)).map((subject) {
      final modifiedChoice = (ChoiceBuilder.fromChoice(choice)..abi4 = subject).build();
      return createChoiceResult(modifiedChoice, gradesProvider, applyAbiPredictions: applyAbiPredictions);
    }).toList();
  }

  static List<ChangeAbiChoiceResult> getChoiceResultsForAbi5(Choice choice, GradesDataProvider gradesProvider, {includeSame = false, applyAbiPredictions = true}) {
    ChoiceOptions options = ChoiceHelper.getAbi5Options(ChoiceBuilder.fromChoice(choice));
    return options.subjects.where((subject) => includeSame || subject != choice.abi5).map((subject) {
      final modifiedChoice = (ChoiceBuilder.fromChoice(choice)..abi5 = subject).build();
      return createChoiceResult(modifiedChoice, gradesProvider, applyAbiPredictions: applyAbiPredictions);
    }).toList();
  }

  static ChangeAbiChoiceResult createChoiceResult(Choice modifiedChoice, GradesDataProvider provider, {applyAbiPredictions = true}) {
    final results = SemesterResult.calculateResultsWithPredictions(modifiedChoice, provider, applyAbiPredictions: applyAbiPredictions);
    final flags = SemesterResult.applyUseFlags(modifiedChoice, results);
    final hurdles = [...AdmissionHurdle.check(modifiedChoice, results, flags, provider), ...GraduationHurdle.check(modifiedChoice, results, flags, provider)];
    return ChangeAbiChoiceResult(modifiedChoice, results, flags, hurdles);
  }

  static (Subject, Subject)? findChangedAbiSubjects(Choice originalChoice, Choice? modifiedChoice) {
    if (modifiedChoice == null) return null;
    for (int i = 0; i < originalChoice.abiSubjects.length; i++) {
      if (originalChoice.abiSubjects[i] != modifiedChoice.abiSubjects[i]) {
        return (originalChoice.abiSubjects[i], modifiedChoice.abiSubjects[i]);
      }
    }
    return null;
  }
}

class ChangeAbiChoiceResultWidget extends StatefulWidget {
  const ChangeAbiChoiceResultWidget({super.key, required this.modifiedResult, required this.originalResult});

  final ChangeAbiChoiceResult originalResult;
  final ChangeAbiChoiceResult modifiedResult;

  @override
  State<ChangeAbiChoiceResultWidget> createState() => _ChangeAbiChoiceResultWidgetState();
}

class _ChangeAbiChoiceResultWidgetState extends State<ChangeAbiChoiceResultWidget> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  Map<Subject, List<SemesterResult>> _filterModifiedSemesterResults(ChangeAbiChoiceResult from, ChangeAbiChoiceResult to) {
    Map<Subject, List<SemesterResult>> filteredResults = {};
    for (MapEntry<Subject, Map<Semester, SemesterResult>> subjectSemesterResultsEntry in from.results.entries) {
      for (MapEntry<Semester, SemesterResult> semesterResultEntry in subjectSemesterResultsEntry.value.entries) {
        SemesterResult? toResult = to.results[subjectSemesterResultsEntry.key]?[semesterResultEntry.key];
        if (toResult == null || semesterResultEntry.value.used && !toResult.used || semesterResultEntry.value.grade != toResult.grade) {
          filteredResults.putIfAbsent(subjectSemesterResultsEntry.key, () => []).add(semesterResultEntry.value);
        }
      }
    }
    return filteredResults;
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final originalSubjects = widget.originalResult.choice.abiSubjects;
    final modifiedSubjects = widget.modifiedResult.choice.abiSubjects;

    final pointsDifference = widget.modifiedResult.flags.pointsTotal - widget.originalResult.flags.pointsTotal;
    final underscoredDifference = widget.modifiedResult.flags.underscored - widget.originalResult.flags.underscored;

    const wrapWidth = 300;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                Wrap(
                  direction: constraints.maxWidth > wrapWidth ? Axis.horizontal : Axis.vertical,
                  spacing: 8,
                  runSpacing: 16,
                  alignment: constraints.maxWidth > wrapWidth ? WrapAlignment.spaceBetween : WrapAlignment.start,
                  crossAxisAlignment: constraints.maxWidth > wrapWidth ? WrapCrossAlignment.center : WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth > wrapWidth ? null : constraints.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < modifiedSubjects.length; i++)
                            if (originalSubjects[i] != modifiedSubjects[i]) ...[
                              const SizedBox(height: 3),
                              SmallSubjectWidget(subject: originalSubjects[i], old: true, choice: widget.originalResult.choice,),
                              const SizedBox(height: 1),
                              Icon(Icons.keyboard_double_arrow_down_rounded, size: 14, color: theme.shadowColor),
                              SmallSubjectWidget(subject: modifiedSubjects[i], old: false, choice: widget.modifiedResult.choice,),
                              const SizedBox(height: 3),
                            ]
                        ],
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth > wrapWidth ? null : constraints.maxWidth,
                      padding: constraints.maxWidth > wrapWidth ? null : const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      decoration: BoxDecoration(
                        color: constraints.maxWidth > wrapWidth ? null : theme.shadowColor.withOpacity(.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 12,
                        children: [
                          if (widget.modifiedResult.hurdles.isNotEmpty)
                            Icon(Icons.warning_amber_rounded, size: 20, color: theme.disabledColor,)
                          else Column(
                            children: [
                              const SizedBox(height: 6,),
                              Text("Ø ${SemesterResult.pointsToAbiGrade(widget.modifiedResult.flags.pointsTotal)}", style: theme.textTheme.displayMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${widget.modifiedResult.flags.pointsTotal}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                              Text("${pointsDifference >= 0 ? "+" : ""}$pointsDifference",
                                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: pointsDifference > 0 ? theme.indicatorColor : pointsDifference < 0 ? theme.disabledColor : theme.primaryColor)),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${widget.modifiedResult.flags.underscored} / 8", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                              Text("${underscoredDifference >= 0 ? "+" : ""}$underscoredDifference",
                                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: underscoredDifference > 0 ? theme.disabledColor : underscoredDifference < 0 ? theme.indicatorColor : theme.shadowColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                AnimatedDrawerTransition(
                  duration: const Duration(milliseconds: 500),
                  margin: const EdgeInsets.only(top: 12),
                  expanded: _expanded,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: constraints.maxWidth,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        decoration: BoxDecoration(
                          color: theme.shadowColor.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.remove_rounded, size: 16, color: theme.disabledColor),
                                  ..._buildDifference(theme, _filterModifiedSemesterResults(widget.originalResult, widget.modifiedResult), CrossAxisAlignment.start, TextAlign.start),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12,),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(Icons.add_rounded, size: 16, color: theme.indicatorColor),
                                  ..._buildDifference(theme, _filterModifiedSemesterResults(widget.modifiedResult, widget.originalResult), CrossAxisAlignment.end, TextAlign.end),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  List<Widget> _buildDifference(ThemeData theme, Map<Subject, List<SemesterResult>> changedResults, CrossAxisAlignment crossAxisAlignment, TextAlign textAlign) {
    return [
      for (MapEntry<Subject, List<SemesterResult>> entry in changedResults.entries) ...[
        const SizedBox(height: 6,),
        Text(entry.key.name, style: theme.textTheme.bodySmall, textAlign: textAlign,),
        Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            for (SemesterResult result in entry.value) Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${result.grade}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.primaryColor, height: 1.6)),
                if (result.semester.semesterCountEquivalent > 1) ...[
                  const SizedBox(width: 4,),
                  Text("(≈ ${result.effectiveGrade})", style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor, height: 1.4))
                ],
                const SizedBox(width: 4,),
                Container(
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: theme.shadowColor.withValues(alpha: .15),
                  ),
                  child: Center(child: Text(result.semester.display, style: theme.textTheme.bodySmall?.copyWith(height: 1.4))),
                )
              ],
            )
          ],
        ),
      ],
    ];
  }
}

class SmallSubjectWidget extends StatelessWidget {
  const SmallSubjectWidget({super.key, required this.subject, required this.old, required this.choice});

  final Choice choice;
  final Subject subject;
  final bool old;

  static TextStyle getTextStyle(ThemeData theme, bool old) {
    return theme.textTheme.displayMedium?.copyWith(
        fontSize: 16, color: old ? theme.shadowColor : theme.primaryColor,
        decoration: old ? TextDecoration.lineThrough : null,
        decorationColor: old ? theme.shadowColor : theme.primaryColor,
        decorationThickness: 2, fontWeight: old ? FontWeight.w500 : FontWeight.w600,
        height: 1.4) ?? const TextStyle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: subject.color.withOpacity(old ? .6 : 1)),
          width: 14,
          height: 14,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(subject.name, style: getTextStyle(theme, old), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,
          ),
        ),
        if (choice.lk == subject) ...[
          const SizedBox(width: 4),
          Text("(LF)", style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: theme.shadowColor, fontWeight: FontWeight.w600)),
        ] else if (choice.substituteMathe && subject == (choice.lk.category == SubjectCategory.info ? choice.ntg1 : choice.mintSg2)) ...[
          const SizedBox(width: 4),
          Text("(M)", style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: theme.shadowColor, fontWeight: FontWeight.w600)),
        ] else if (choice.substituteDeutsch && subject == choice.mintSg2) ...[
          const SizedBox(width: 4),
          Text("(D)", style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: theme.shadowColor, fontWeight: FontWeight.w600)),
        ]
      ],
    );
  }
}


