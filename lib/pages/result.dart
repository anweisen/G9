import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/grades.dart';
import '../logic/choice.dart';
import '../logic/results.dart';
import '../logic/types.dart';
import '../provider/grades.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../widgets/subpage.dart';
import 'subject.dart';
import 'grade.dart';

class SubjectResultPage extends StatelessWidget {
  const SubjectResultPage({super.key, required this.subject, required this.results, required this.choice});

  final Subject subject;
  final Map<Semester, SemesterResult> results;
  final Choice choice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradesProvider = Provider.of<GradesDataProvider>(context);

    bool abi = choice.abiSubjects.contains(subject);
    bool lk = choice.lk == subject;
    bool seminar = choice.seminar == subject;
    bool profil = choice.profil12 == subject || choice.profil13 == subject;

    return SubpageSkeleton(
        title: Row(children: [
          SubjectPageTitle(subject: subject),
          if (abi || profil || seminar) Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(6)),
              child: Text(lk ? "Leistungsfach" : abi ? "Abiturfach" : profil ? "Profilfach" : seminar ? "Seminarfach" : "", style: theme.textTheme.displayMedium?.copyWith(height: 1.25, color: theme.scaffoldBackgroundColor),)
          ),
        ]),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _buildInfoWidgets(theme),
              ),
              const SizedBox(height: 20,),

              Text("Qualifikationsphase", style: theme.textTheme.bodySmall),
              for (Semester semester in Semester.qPhaseEquivalents(subject.category))
                if (choice.hasSubjectInSemester(subject, semester))
                  _buildSemester(semester, theme, gradesProvider),


              if (abi) ..._buildAbi(theme, gradesProvider),
            ],
          )
        ]);
  }

  Widget _buildSemester(Semester semester, ThemeData theme, GradesDataProvider gradesProvider) {
    SemesterResult? result = results[semester];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(semester.display, style: theme.textTheme.bodyMedium,),
              if (semester.semesterCountEquivalent == 2)
                Text("doppelte Einbringung (30 P.)", style: theme.textTheme.bodySmall),
            ],
          ),
          Row(
            children: [
              Column(
                children: [
                  if (!(result?.prediction ?? true)) Row(
                    children: [
                      Text("Ø", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w300)),
                      const SizedBox(width: 4),
                      Text(GradeHelper.formatSemesterAverage(gradesProvider.getGrades(subject.id, semester: semester)), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (semester.semesterCountEquivalent > 1)
                    Text("(≈ ${result?.effectiveGrade})", style: theme.textTheme.bodySmall),
                  if (result?.prediction ?? true)
                    Text("Prognose", style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                  width: 36,
                  height: 27,
                  decoration: (result?.used ?? false) ? BoxDecoration(color: (result?.grade ?? 15) >= 5 ? theme.primaryColor : theme.splashColor, borderRadius: BorderRadius.circular(6)) : null,
                  child: Center(child: Text(result?.grade.toString() ?? "-",
                        style: (result?.used ?? false) ? theme.textTheme.labelMedium?.copyWith(color: (result?.grade ?? 15) < 5 ? theme.indicatorColor : null) : theme.textTheme.bodyMedium,)
                  )
              ),
              const SizedBox(width: 6),
              SizedBox(width: 10, child: Column(
                children: [
                  if (result?.replacedByJoker ?? false) Icon(Icons.join_inner_rounded, size: 16, color: theme.primaryColor)
                  else if (result?.useForced ?? false) Icon(Icons.check_circle, size: 16, color: theme.primaryColor)
                  else if (result?.useExtra ?? false) Icon(Icons.check_circle_outline, size: 16, color: theme.primaryColor)
                  else if (result?.useJoker ?? false) Icon(Icons.join_full_rounded, size: 16, color: theme.primaryColor)
                ],)
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAbi(ThemeData theme, GradesDataProvider gradesProvider) {
    SemesterResult? result = results[Semester.abi];
    return [
      const SizedBox(height: 20,),
      Text("Abiturprüfung", style: theme.textTheme.bodySmall),
      const SizedBox(height: 6,),
      SubjectResultAbiPrediction(subject: subject, result: result, choice: choice,)
    ];
  }

  List<Widget> _buildInfoWidgets(ThemeData theme) {
    int semesters = choice.numberOfSemestersFor(subject);
    int minSemesters = SemesterResult.getMinSemestersForSubject(choice, subject);
    int maxSemesters = SemesterResult.getMaxSemesterForSubject(choice, subject);
    bool joker = SemesterResult.canUseJokerForSubject(choice, subject);

    int freeSemestersUsed = 0;
    Semester? jokerUsed; // this semester is replaced
    Semester? usedVkExtra;
    (Subject, SemesterResult)? jokerReplacesSemester; // this semester is used as a replacement for
    for (Semester semester in Semester.qPhaseEquivalents(subject.category)) {
      SemesterResult? result = results[semester];
      if (result == null) continue;
      if (result.replacedByJoker) jokerUsed = semester;
      if (result.useExtra) freeSemestersUsed += 1;
      if (result.useJoker) jokerReplacesSemester = result.jokerResult;
      if (result.useVk) usedVkExtra = semester;
    }

    bool extraVkMintSg2 = (choice.vk != null && (choice.vk == subject || choice.mintSg2 == subject));
    bool onlySg = choice.lk != subject && subject.category == SubjectCategory.sg && choice.mintSg2.category != SubjectCategory.sg && choice.mintSg2.category != SubjectCategory.sbs;
    bool onlyNtg = choice.lk != subject && subject.category == SubjectCategory.ntg && choice.mintSg2.category != SubjectCategory.ntg && choice.mintSg2.category != SubjectCategory.info;

    return [
      if (minSemesters == 4)
        _buildInfoWidget(theme, "verpflichtend alle $minSemesters Einbringungen", Icons.check_circle_rounded)
      else if (minSemesters > 1)
        _buildInfoWidget(theme, "verpflichtend min. $minSemesters Einbringungen", Icons.check_circle_rounded)
      else if (minSemesters == 1)
        _buildInfoWidget(theme, "verpflichtend min. $minSemesters Einbringung", Icons.check_circle_rounded)
      else
        _buildInfoWidget(theme, "keine verpflichtende Einbringung", null),

      if (extraVkMintSg2)
        _buildInfoWidget(theme, "+1 verpflichtende Einbringung in ${choice.vk?.name} oder ${choice.mintSg2.name}", null),
      if (usedVkExtra != null)
        _buildInfoWidget(theme, "verpflichtende Einbringung von ${usedVkExtra.display} für Vertiefungskurs genutzt", Icons.stars_rounded),

      if (onlySg)
        _buildInfoWidget(theme, "einzige Fremdsprache", null),
      if (onlyNtg)
        _buildInfoWidget(theme, "einzige Naturwissenschaft", null),

      if (maxSemesters < semesters)
        _buildInfoWidget(theme, "max. $maxSemesters Einbringungen möglich", Icons.lock_open_rounded),

      if (jokerUsed != null)
        _buildInfoWidget(theme, "Optionsregel streicht ${jokerUsed.display}", Icons.join_inner_rounded)
      else if (!joker)
        _buildInfoWidget(theme, "Optionsregel nicht anwendbar", Icons.warning_amber_rounded)
      else if (minSemesters != 0)
        _buildInfoWidget(theme, "Optionsregel anwendbar", null),

      if (freeSemestersUsed == 1)
        _buildInfoWidget(theme, "$freeSemestersUsed freie Einbringung genutzt", Icons.check_circle_outline)
      else if (freeSemestersUsed > 1)
        _buildInfoWidget(theme, "$freeSemestersUsed freie Einbringungen genutzt", Icons.check_circle_outline),

      if (jokerReplacesSemester != null)
        _buildInfoWidget(theme, "Einbringung per Optionsregel ersetzt ${jokerReplacesSemester.$1.name} ${jokerReplacesSemester.$2.semester.display}", Icons.join_full_rounded),
    ];
  }

  Widget _buildInfoWidget(ThemeData theme, String text, IconData? icon) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.info_outline_rounded, size: 16, color: theme.textTheme.displayMedium?.color),
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: theme.textTheme.displayMedium?.copyWith(height: 1.25), softWrap: true, maxLines: 3, textWidthBasis: TextWidthBasis.longestLine,)),
          ],
        ),
    );
  }
}

class SubjectResultAbiPrediction extends StatelessWidget {
  const SubjectResultAbiPrediction({super.key, required this.subject, required this.result, required this.choice,});

  final Choice choice;
  final Subject subject;
  final SemesterResult? result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradesProvider = Provider.of<GradesDataProvider>(context);

    Color contrastColor = subject.color.computeLuminance() > 0.80 ? (theme.brightness == Brightness.light ? Colors.black : Colors.black87) : Colors.white;

    bool prediction = result?.prediction ?? true;
    int predicted = gradesProvider.getAbiPrediction(subject.id) ?? result?.effectiveGrade ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: subject.color.withAlpha(theme.brightness == Brightness.dark ? 66 : 120),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: subject.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Wrap(
                      children: [
                        Text(_buildAbiAreaWidget(), style: theme.textTheme.displayMedium?.copyWith(color: contrastColor, height: 1.25), softWrap: true, maxLines: 3, overflow: TextOverflow.ellipsis,),
                        const SizedBox(width: 4),
                        Icon(Icons.check_rounded, size: 16, color: contrastColor)
                      ],
                    )
                ),
              ),
            ],
          ),

          const SizedBox(height: 4,),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prediction ? "Prognose" : "Ergebnis", style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1,),
                    Text("in vierfacher Wertung (max. 60 P.)", style: theme.textTheme.bodySmall, softWrap: true, maxLines: 3,),
                  ],
                ),
              ),

              Row(
                children: [
                  if (!prediction) Row(
                    children: [
                      Text("Ø", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w300)),
                      const SizedBox(width: 4),
                      Text(GradeHelper.formatSemesterAverage(gradesProvider.getGrades(subject.id, semester: Semester.abi)), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                      width: 36,
                      height: 27,
                      decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(6)),
                      child: Center(child: Text(result?.grade.toString() ?? "-",
                            style: theme.textTheme.labelMedium?.copyWith(color: theme.scaffoldBackgroundColor),)
                      )
                  ),
                  const SizedBox(width: 6),
                  Text("(≈ ${result?.effectiveGrade})", style: theme.textTheme.displayMedium?.copyWith(color: null, height: 1.5)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16,),

          Column(
            children: [
              for (GradeEntry entry in gradesProvider.getGrades(subject.id, semester: Semester.abi))
                ... [Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        height: 22,
                        width: 26,
                        decoration: BoxDecoration(
                          color: subject.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(GradeTypSelectionPage.getIcon(entry.type), size: 16, color: contrastColor)
                    ),
                    const SizedBox(width: 8,),
                    Text("${entry.grade}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.primaryColor, height: 1.25)),
                    const SizedBox(width: 4,),
                    Flexible(child: Text(entry.type.name, style: theme.textTheme.displayMedium?.copyWith(height: 1.25), softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis))
                  ],
                ), const SizedBox(height: 8,)],
            ],
          ),

          if (prediction)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => gradesProvider.setAbiPrediction(subject.id, max(min(predicted + 1, 15), 0)),
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: predicted >= 15 ? Colors.transparent : theme.textTheme.labelSmall!.color!, width: 1.5))),
                            child: Icon(Icons.add_rounded, size: 16, color: predicted >= 15 ? Colors.transparent : theme.textTheme.labelSmall?.color)
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        width: 48,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: theme.textTheme.labelSmall!.color!, width: 2))),
                        child: Text("$predicted", style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => gradesProvider.setAbiPrediction(subject.id, max(min(predicted - 1, 15), 0)),
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: predicted <= 0 ? Colors.transparent : theme.textTheme.labelSmall!.color!, width: 1.5))),
                            child: Icon(Icons.remove_rounded, size: 16, color: predicted <= 0 ? Colors.transparent : theme.textTheme.labelSmall?.color)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6,),
                  GestureDetector(
                    onTap: () => gradesProvider.clearAbiPrediction(subject.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: theme.textTheme.labelSmall!.color!, width: 2))),
                      child: Text("Prognose zurücksetzen", style: theme.textTheme.displayMedium?.copyWith(color: gradesProvider.getAbiPrediction(subject.id) != null
                          ? theme.textTheme.bodyMedium?.color : theme.textTheme.labelSmall?.color, height: 1.25), softWrap: true, maxLines: 2,),
                    ),
                  ),
                  const SizedBox(height: 8,),
                  GestureDetector(
                    onTap: () => SubpageController.of(context).openSubpage(SubjectPage(subject: subject, semester: Semester.abi, key: GlobalKey(),)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(6)),
                      child: Text("Ergebnisse eintragen", style: theme.textTheme.displayMedium?.copyWith(color: theme.textTheme.labelMedium?.color, height: 1.25), softWrap: true, maxLines: 2,),
                    ),
                  ),
                ],
              )
        ],
      ),
    );
  }

  String _buildAbiAreaWidget() {
    if (subject.category == SubjectCategory.abi) {
      return subject.name;
    }
    if (choice.substituteMathe && choice.mintSg2 == subject) {
      return "Substituiert Mathe";
    }
    if (choice.substituteDeutsch && choice.mintSg2 == subject) {
      return "Substituiert Deutsch";
    }
    if (choice.substituteMathe && subject.category == SubjectCategory.sg) {
      return "Fremdsprache";
    }
    if (choice.substituteDeutsch && subject.category == SubjectCategory.ntg) {
      return "Naturwissenschaft";
    }
    if ((choice.lk.category != SubjectCategory.sg && choice.lk.category != SubjectCategory.ntg || subject == choice.lk)
        && (subject.category == SubjectCategory.sg || subject.category == SubjectCategory.ntg)) {
      return "Naturwissenschaft / Fremdsprache";
    }
    if ((choice.lk.category != SubjectCategory.gpr || subject == choice.lk) && subject.category == SubjectCategory.gpr) {
      return "Gesellschaftswissenschaft";
    }
    return "Freie Wahl";
  }
}
