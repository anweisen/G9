import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/hurdles.dart';
import '../logic/results.dart';
import '../logic/types.dart';
import '../widgets/skeleton.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import 'settings.dart';

class ChangeAbiSubpage extends StatelessWidget {
  const ChangeAbiSubpage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final gradesProvider = Provider.of<GradesDataProvider>(context);
    final choice = Provider.of<SettingsDataProvider>(context).choice;

    final currentResult = ChangeAbiChoiceResult.createChoiceResult(choice!, gradesProvider);
    final choices = ChangeAbiChoiceResult.getSortedChoiceResultsForAbi(choice, currentResult, gradesProvider);

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

  static ChangeAbiChoiceResult? getBetterChoiceResult(Choice currentChoice, ChangeAbiChoiceResult currentResult, GradesDataProvider gradesProvider) {
    List<ChangeAbiChoiceResult> results = getSortedChoiceResultsForAbi(currentChoice, currentResult, gradesProvider);
    if (results.isEmpty) return null;
    if (results.first.flags.pointsTotal > currentResult.flags.pointsTotal) return results.first;
    return null;
  }

  static List<ChangeAbiChoiceResult> getSortedChoiceResultsForAbi(Choice currentChoice, ChangeAbiChoiceResult currentResult, GradesDataProvider gradesProvider) {
    List<ChangeAbiChoiceResult> results = getChoiceResultsForAbi4(currentChoice, gradesProvider) + getChoiceResultsForAbi5(currentChoice, gradesProvider);
    results.sort((a, b) {
      if (a.hurdles.isEmpty && b.hurdles.isNotEmpty) return -1;
      if (a.hurdles.isNotEmpty && b.hurdles.isEmpty) return 1;
      if (a.flags.underscored != b.flags.underscored) return a.flags.underscored.compareTo(b.flags.underscored);
      return b.flags.pointsTotal.compareTo(a.flags.pointsTotal);
    });
    return results;
  }

  static List<ChangeAbiChoiceResult> getChoiceResultsForAbi4(Choice choice, GradesDataProvider gradesProvider) {
    ChoiceOptions options = ChoiceHelper.getAbi4Options(ChoiceBuilder.fromChoice(choice));
    return options.subjects.where((subject) => subject != choice.abi4).map((subject) {
      final modifiedChoice = (ChoiceBuilder.fromChoice(choice)..abi4 = subject).build();
      return createChoiceResult(modifiedChoice, gradesProvider);
    }).toList();
  }

  static List<ChangeAbiChoiceResult> getChoiceResultsForAbi5(Choice choice, GradesDataProvider gradesProvider) {
    ChoiceOptions options = ChoiceHelper.getAbi5Options(ChoiceBuilder.fromChoice(choice));
    return options.subjects.where((subject) => subject != choice.abi5).map((subject) {
      final modifiedChoice = (ChoiceBuilder.fromChoice(choice)..abi5 = subject).build();
      return createChoiceResult(modifiedChoice, gradesProvider);
    }).toList();
  }

  static ChangeAbiChoiceResult createChoiceResult(Choice modifiedChoice, GradesDataProvider provider) {
    final results = SemesterResult.calculateResultsWithPredictions(modifiedChoice, provider);
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

class ChangeAbiChoiceResultWidget extends StatelessWidget {
  const ChangeAbiChoiceResultWidget({super.key, required this.modifiedResult, required this.originalResult});

  final ChangeAbiChoiceResult originalResult;
  final ChangeAbiChoiceResult modifiedResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final originalSubjects = originalResult.choice.abiSubjects;
    final modifiedSubjects = modifiedResult.choice.abiSubjects;

    final pointsDifference = modifiedResult.flags.pointsTotal - originalResult.flags.pointsTotal;
    final underscoredDifference = modifiedResult.flags.underscored - originalResult.flags.underscored;

    const wrapWidth = 300;

    return Container(
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
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
                        SmallSubjectWidget(subject: originalSubjects[i], old: true, choice: modifiedResult.choice,),
                        const SizedBox(height: 1),
                        Icon(Icons.keyboard_double_arrow_down_rounded, size: 14, color: theme.shadowColor),
                        SmallSubjectWidget(subject: modifiedSubjects[i], old: false, choice: modifiedResult.choice,),
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
                    if (modifiedResult.hurdles.isNotEmpty)
                      Icon(Icons.warning_amber_rounded, size: 20, color: theme.disabledColor,)
                    else Column(
                      children: [
                        const SizedBox(height: 6,),
                        Text("Ø ${SemesterResult.pointsToAbiGrade(modifiedResult.flags.pointsTotal)}", style: theme.textTheme.displayMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${modifiedResult.flags.pointsTotal}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text("${pointsDifference >= 0 ? "+" : ""}$pointsDifference",
                            style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: pointsDifference > 0 ? theme.indicatorColor : pointsDifference < 0 ? theme.disabledColor : theme.primaryColor)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${modifiedResult.flags.underscored} / 8", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text("${underscoredDifference >= 0 ? "+" : ""}$underscoredDifference",
                            style: theme.textTheme.displayMedium?.copyWith(fontSize: 13, color: underscoredDifference > 0 ? theme.disabledColor : underscoredDifference < 0 ? theme.indicatorColor : theme.shadowColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

class SmallSubjectWidget extends StatelessWidget {
  const SmallSubjectWidget({super.key, required this.subject, required this.old, required this.choice});

  final Choice choice;
  final Subject subject;
  final bool old;

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
        Text(subject.name, style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 16, color: old ? theme.shadowColor : theme.primaryColor,
            decoration: old ? TextDecoration.lineThrough : null,
            decorationThickness: 2, fontWeight: old ? FontWeight.w500 : FontWeight.w600,
            height: 1.4), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,
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


