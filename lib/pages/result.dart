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
          Expanded(child: Column(
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
          ))
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
              if (SemesterResult.getQSemesterCountEquivalent(semester) == 2)
                Text("doppelte Einbringung (30 P.)", style: theme.textTheme.bodySmall),
            ],
          ),
          Row(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Text("Ø", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w300)),
                      const SizedBox(width: 4),
                      Text(GradeHelper.formatSemesterAverage(gradesProvider.getGrades(subject.id, semester: semester)), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (SemesterResult.getQSemesterCountEquivalent(semester) > 1)
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
      SubjectResultAbiPrediction(subject: subject, result: result)
    ];
  }

  List<Widget> _buildInfoWidgets(ThemeData theme) {
    int minSemesters = SemesterResult.getMinSemestersForSubject(choice, subject);
    int maxSemesters = SemesterResult.getMaxSemesterForSubject(choice, subject);
    int semesters = choice.numberOfSemestersFor(subject);
    bool joker = SemesterResult.canUseJokerForSubject(choice, subject);

    int freeSemestersUsed = 0;
    Semester? jokerUsed;
    for (Semester semester in Semester.qPhaseEquivalents(subject.category)) {
      SemesterResult? result = results[semester];
      if (result == null) continue;
      if (result.replacedByJoker) {
        jokerUsed = semester;
      }
      if (result.useExtra || result.useJoker) {
        freeSemestersUsed += 1;
      }
    }

    bool extraVkMintSg2 = (choice.vk != null && (choice.vk == subject || choice.mintSg2 == subject));

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

      if (maxSemesters < semesters)
        _buildInfoWidget(theme, "max. $maxSemesters Einbringungen möglich", Icons.lock_open_rounded),

      if (jokerUsed != null)
        _buildInfoWidget(theme, "Optionsregel streicht ${jokerUsed.display}", Icons.join_inner_rounded)
      else if (joker)
        _buildInfoWidget(theme, "Optionsregel anwendbar", null)
      else
        _buildInfoWidget(theme, "Optionsregel nicht anwendbar", Icons.warning_amber_rounded),

      if (freeSemestersUsed == 1)
        _buildInfoWidget(theme, "$freeSemestersUsed freie Einbringung genutzt", Icons.check_circle_outline)
      else if (freeSemestersUsed > 1)
        _buildInfoWidget(theme, "$freeSemestersUsed freie Einbringungen genutzt", Icons.check_circle_outline),

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
            Flexible(child: Text(text, style: theme.textTheme.displayMedium?.copyWith(height: 1.25), softWrap: true, maxLines: 3,)),
          ],
        ),
    );
  }
}

class SubjectResultAbiPrediction extends StatelessWidget {
  const SubjectResultAbiPrediction({
    super.key,
    required this.subject,
    required this.result,
  });

  final Subject subject;
  final SemesterResult? result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradesProvider = Provider.of<GradesDataProvider>(context);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prediction ? "Prognose" : "Prüfungsergebnis", style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1,),
                    Text("in vierfacher Wertung (max. 60 P.)", style: theme.textTheme.bodySmall, softWrap: true, maxLines: 3,),
                  ],
                ),
              ),

              Row(
                children: [
                  Row(
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

          for (GradeEntry entry in gradesProvider.getGrades(subject.id, semester: Semester.abi))
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(GradeTypSelectionPage.getIcon(entry.type), size: 16, color: theme.textTheme.displayMedium?.color),
                const SizedBox(width: 8,),
                Text(entry.type.name, style: theme.textTheme.displayMedium),
                const SizedBox(width: 8,),
                Text("${entry.grade} P.", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),

          if (prediction)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => gradesProvider.setAbiPrediction(subject.id, max(min(predicted + 1, 15), 1)),
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: theme.textTheme.labelSmall!.color!, width: 1.5))),
                            child: Icon(Icons.add_rounded, size: 16, color: theme.textTheme.labelSmall?.color)
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: theme.textTheme.labelSmall!.color!, width: 2))),
                        child: Text("$predicted", style: theme.textTheme.bodyMedium),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => gradesProvider.setAbiPrediction(subject.id, max(min(predicted - 1, 15), 1)),
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: theme.textTheme.labelSmall!.color!, width: 1.5))),
                            child: Icon(Icons.remove_rounded, size: 16, color: theme.textTheme.labelSmall?.color)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12,),
                  GestureDetector(
                    onTap: () => SubpageController.of(context).openSubpage(SubjectPage(subject: subject, semester: Semester.abi, key: GlobalKey(),)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(6)),
                      child: Text("Ergebnisse eintragen", style: theme.textTheme.displayMedium?.copyWith(color: theme.textTheme.labelMedium?.color, height: 1.25), softWrap: true, maxLines: 2,),
                    ),
                  )
                ],
              )
        ],
      ),
    );
  }
}



