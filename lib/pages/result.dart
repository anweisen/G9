import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/grades.dart';
import '../logic/choice.dart';
import '../logic/results.dart';
import '../logic/types.dart';
import '../provider/grades.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';

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
                  child: Center(child: Text(result?.grade.toString() ?? "-", style: (result?.used ?? false) ? theme.textTheme.labelMedium?.copyWith(color: (result?.grade ?? 15) < 5 ? theme.indicatorColor : null) : theme.textTheme.bodyMedium,))
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

