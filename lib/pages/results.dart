import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/types.dart';
import '../logic/results.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/nav.dart';
import '../widgets/subpage.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const double leftOffset = 36;

    var settings = Provider.of<SettingsDataProvider>(context);
    var grades = Provider.of<GradesDataProvider>(context);

    var results = SemesterResult.calculateResultsWithPredictions(settings.choice!, grades);
    var flags = SemesterResult.applyUseFlags(settings.choice!, results);

    return SubpageController(
      child: Scaffold(
        // appBar: AppBar(title: const Text("Fächer"), actions: [Text("asd")]),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: leftOffset),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Einbringungen", style: theme.textTheme.headlineMedium),
                    ],
                  ),
                ),

                if (settings.choice != null && !flags.isEmpty)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                      children: [
                        ...results.entries.map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: leftOffset, vertical: 12),
                            child: SubjectCard(subject: entry.key, results: entry.value, choice: settings.choice!,))
                        ),

                        const SizedBox(height: 20),

                        _buildLegendText(leftOffset, theme, "Einbringung: Pflicht", Icons.check_circle),
                        _buildLegendText(leftOffset, theme, "Einbringung: Frei", Icons.check_circle_outline),
                        _buildLegendText(leftOffset, theme, "Optionsregel: Gestrichen", Icons.close_rounded),
                        _buildLegendText(leftOffset, theme, "Optionsregel: Einbringung", Icons.join_full_rounded),

                        const SizedBox(height: 40),

                        ...?settings.choice?.abiSubjects.map((subject) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: leftOffset, vertical: 10),
                          child: AbiSubjectCard(subject: subject, result: results[subject]![Semester.abi]!),
                        )),

                        const SizedBox(height: 40),

                        _buildText(leftOffset, theme, "Pflicht Einbringungen", "${flags.forcedSemesters}"),
                        const SizedBox(height: 8),
                        _buildText(leftOffset, theme, "Punkte Q Phase", "${flags.pointsQ}"),
                        _buildText(leftOffset, theme, "Punkte Abitur", "${flags.pointsAbi}"),
                        const SizedBox(height: 8),
                        _buildText(leftOffset, theme, "insgesamt Punkte", "${flags.pointsQ + flags.pointsAbi}"),
                        _buildText(leftOffset, theme, "erreichter Schnitt", SemesterResult.pointsToAbiGrade(flags.pointsQ + flags.pointsAbi)),

                      ],

                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const Nav(),
        extendBody: true,
      ),
    );
  }

  Widget _buildText(double leftOffset, ThemeData theme, String text, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: leftOffset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildLegendText(double leftOffset, ThemeData theme, String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: leftOffset),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500)),
        ],
      ),
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
                    borderRadius: BorderRadius.circular(8),
                    color: subject.color),
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 10),
              Text(subject.name,
                  style: theme.textTheme.bodyMedium),
              const Spacer(),
              Icon(Icons.info, color: theme.textTheme.bodySmall?.color, size: 12),
              const SizedBox(width: 4),
              Text("min. ${SemesterResult.getMinSemestersForSubject(choice, subject)}", style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var semester in Semester.qPhase)
                _buildSemester(theme, semester, results[semester]),
          ],
        )
      ],
    );
  }

  Widget _buildSemester(ThemeData theme, Semester semester, SemesterResult? result) {
    final textStyle = _getTextStyleFor(theme, result);

    return Column(
      children: [
        Text(semester.display, style: theme.textTheme.bodySmall),
        Row(
          children: [
            Text(result?.grade.toString() ?? "-", style: textStyle?.copyWith(decoration: (result?.replacedByJoker ?? false) ? TextDecoration.lineThrough : null)),
            const SizedBox(width: 3),
            if (result?.replacedByJoker ?? false) Icon(Icons.close_rounded, size: 13, color: textStyle?.color)
            else if (result?.useForced ?? false) Icon(Icons.check_circle, size: 12, color: textStyle?.color)
            else if (result?.useExtra ?? false) Icon(Icons.check_circle_outline, size: 12, color: textStyle?.color)
            else if (result?.useJoker ?? false) Icon(Icons.join_full_rounded, size: 14, color: textStyle?.color)
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
  const AbiSubjectCard({super.key, required this.subject, required this.result});

  final Subject subject;
  final SemesterResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = _getTextStyleFor(theme, result);

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
                    borderRadius: BorderRadius.circular(8),
                    color: subject.color),
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 10),
              Text(subject.name, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text("${result.grade}", style: textStyle),
            ],
          ),
        )
      ],
    );
  }
}
