import 'package:abi_app/pages/hurdles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/subpage.dart';
import '../widgets/skeleton.dart';
import '../logic/hurdles.dart';
import '../logic/choice.dart';
import '../logic/types.dart';
import '../logic/results.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../pdf/pdf_widget.dart';
import 'result.dart';
import 'settings.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    var settings = Provider.of<SettingsDataProvider>(context);
    var grades = Provider.of<GradesDataProvider>(context);

    var results = SemesterResult.calculateResultsWithPredictions(settings.choice!, grades);
    var flags = SemesterResult.applyUseFlags(settings.choice!, results);
    var admissionHurdleCheckResults = AdmissionHurdle.check(settings.choice!, results, flags, grades);
    var graduationHurdleCheckResults = GraduationHurdle.check(settings.choice!, results, flags, grades);

    return PageSkeleton(
        title: const PageTitle(title: "Ergebnisse"),
        children: [

          Text("Einbringungen / Halbjahresleistungen", style: theme.textTheme.bodySmall),
          ...results.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SubjectCard(subject: entry.key, results: entry.value, choice: settings.choice!,))
          ),

          const SizedBox(height: 24),

          Text("Abiturprüfungen", style: theme.textTheme.bodySmall),
          ...?settings.choice?.abiSubjects.map((subject) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AbiSubjectCard(subject: subject, result: results[subject]![Semester.abi]!, results: results[subject]!, choice: settings.choice!,),
          )),

          const SizedBox(height: 24),

          _buildContainer(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 18, color: theme.shadowColor),
                  const SizedBox(width: 5),
                  Text("Statistiken", style: theme.textTheme.bodySmall),
                ],
              ),

              _buildText(theme, "Pflicht Einbringungen", "${flags.forcedSemesters}"),
              _buildText(theme, "Punkte Q Phase", "${flags.pointsQ}"),
              _buildText(theme, "Punkte Abitur", "${flags.pointsAbi}"),
              _buildText(theme, "Insgesamt Punkte", "${flags.pointsTotal}"),
              _buildText(theme, "Erreichter Schnitt", SemesterResult.pointsToAbiGrade(flags.pointsTotal)),
            ],
          )),

          const SizedBox(height: 24),

          SubpageTrigger(
            createSubpage: () => HurdlesPage(checkResults: [...admissionHurdleCheckResults, ...graduationHurdleCheckResults],),
            child: _buildContainer(Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_rounded, size: 18, color: theme.shadowColor),
                        const SizedBox(width: 5),
                        Text("Zulassungs- & Anerkennungshürden", style: theme.textTheme.bodySmall),
                      ],
                    ),
                    if (admissionHurdleCheckResults.isEmpty && graduationHurdleCheckResults.isEmpty) Text("Alle nötigen Hürden erfüllt", style: theme.textTheme.bodyMedium)
                    else Text("Nötigen Hürden nicht erfüllt", style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
                  ],
                ),
                if (admissionHurdleCheckResults.isEmpty && graduationHurdleCheckResults.isEmpty) Icon(Icons.check_circle, size: 20, color: theme.primaryColor)
                else Icon(Icons.warning_amber_rounded, size: 22, color: theme.disabledColor)
              ],
            ))
          ),

          const SizedBox(height: 24),

          SubpageTrigger(
              createSubpage: () => const PdfPreviewPage(),
              child: SettingsPage.buildButton(theme, "Notenübersicht drucken", Icons.print_rounded, null, primary: true)
          ),
        ]);
  }

  Widget _buildContainer(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool thin = constraints.maxWidth < 500;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            border: thin ? null : Border.all(color: Theme.of(context).dividerColor, width: 2),
            color: thin ? Theme.of(context).dividerColor : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildText(ThemeData theme, String text, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class SubjectCard extends StatelessWidget {
  const SubjectCard({super.key, required this.subject, required this.results, required this.choice});

  final Subject subject;
  final Map<Semester, SemesterResult> results;
  final Choice choice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => SubpageController.of(context).openSubpage(SubjectResultPage(subject: subject, results: results, choice: choice, key: GlobalKey(),)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.dividerColor,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: subject.color),
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(subject.name, style: theme.textTheme.bodyMedium, softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var semester in Semester.qPhaseEquivalents(subject.category))
                      _buildSemester(theme, semester, results[semester]),
                  ],
                )
              ],
            );
          }
          const nameWidth = 230.0; // fixed
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor, width: 2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: nameWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: subject.color),
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 10),
                          Flexible(child: Text(subject.name, style: theme.textTheme.bodyMedium, softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,)),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var semester in Semester.qPhaseEquivalents(subject.category))
                            _buildSemester(theme, semester, results[semester]),
                        ],
                      ),
                    )
                  ],
                ),
                // const SizedBox(height: 10),

              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSemester(ThemeData theme, Semester semester, SemesterResult? result) {
    final textStyle = _getTextStyleFor(theme, result);
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(semester.detailedDisplay, style: theme.textTheme.bodySmall),
        Row(
          children: [
            Text((result != null && !result.flagged) ? result.grade.toString() : "-", style: textStyle),
            const SizedBox(width: 3),
            if (result?.replacedByJoker ?? false) Icon(Icons.join_inner_rounded, size: 13, color: textStyle?.color)
            else if (result?.useForced ?? false) Icon(Icons.check_circle, size: 12, color: textStyle?.color)
            else if (result?.useExtra ?? false) Icon(Icons.check_circle_outline, size: 12, color: textStyle?.color)
            else if (result?.useJoker ?? false) Icon(Icons.join_full_rounded, size: 14, color: textStyle?.color)
            else if (result?.useVk ?? false) Icon(Icons.stars_rounded, size: 12, color: textStyle?.color)
          ]
        ),
      ],
    );
  }
}

TextStyle? _getTextStyleFor(ThemeData theme, SemesterResult? result) {
  return result?.prediction ?? false
      ? theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.normal, color: theme.textTheme.bodySmall?.color)
      : result?.used ?? false
        ? theme.textTheme.bodyMedium
        : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal);
}

class AbiSubjectCard extends StatelessWidget {
  const AbiSubjectCard({super.key, required this.subject, required this.result, required this.results, required this.choice});

  final Subject subject;
  final SemesterResult result;
  final Map<Semester, SemesterResult> results;
  final Choice choice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = _getTextStyleFor(theme, result);

    return GestureDetector(
      onTap: () => SubpageController.of(context).openSubpage(SubjectResultPage(subject: subject, results: results, choice: choice, key: GlobalKey(),)),
      child: LayoutBuilder(
        builder: (context, constraints) {
            if (constraints.maxWidth < 500) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.dividerColor,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: subject.color),
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(subject.name, style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        Text("(≈ ${result.effectiveGrade})", style: theme.textTheme.displayMedium?.copyWith(color: textStyle?.color, height: 1.5)),
                        const SizedBox(width: 4),
                        Text("${result.grade}", style: textStyle),
                      ],
                    ),
                  )
                ],
              );
            }
            const nameWidth = 230.0; // fixed
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: nameWidth,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: subject.color),
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 10),
                            Flexible(child: Text(subject.name, style: theme.textTheme.bodyMedium, softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,)),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 3; i++) const SizedBox(width: 36,), // spacing approximation
                            Column(
                              children: [
                                const SizedBox(height: 4),
                                Text(result.prediction ? "Prognose" : "Prüfung", style: theme.textTheme.bodySmall),
                                Row(
                                  children: [
                                    Text("(≈ ${result.effectiveGrade})", style: theme.textTheme.displayMedium?.copyWith(color: textStyle?.color, height: 1.5)),
                                    const SizedBox(width: 4),
                                    Text("${result.grade}", style: textStyle),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  // const SizedBox(height: 10),

                ],
              ),
            );
        }
      ),
    );
  }
}
