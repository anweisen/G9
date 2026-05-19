import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/skeleton.dart';
import '../logic/choice.dart';
import '../logic/grades.dart';
import '../logic/results.dart';
import '../logic/types.dart';
import '../provider/grades.dart';

class TopSubjectsSubpage extends StatefulWidget {
  const TopSubjectsSubpage({super.key, required this.choice, required this.results});

  final Choice choice;
  final Map<Subject, Map<Semester, SemesterResult>> results;

  @override
  State<TopSubjectsSubpage> createState() => _TopSubjectsSubpageState();
}

class _TopSubjectsSubpageState extends State<TopSubjectsSubpage> {

  bool _includeUnused = true;
  bool _includeAbiSem = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    final stats = SemesterResult.calculateStatistics(widget.choice, widget.results, includeEmpty: true, includeAbiSem: _includeAbiSem, includeUnused: _includeUnused);

    return SubpageSkeleton(
        title: const PageTitle(title: "Beste Fächer"),
        children: [
          Text("Berechnungsfilter", style: theme.textTheme.bodySmall),
          const SizedBox(height: 6,),
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _includeUnused = !_includeUnused),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.dividerColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Icon(_includeUnused ? Icons.check_rounded : Icons.close_rounded, size: 18, color: _includeUnused ? theme.primaryColor : theme.shadowColor, weight: 700),
                        Flexible(child: Text("Nicht eingebrachte Halbjahre", style: theme.textTheme.displayMedium?.copyWith(color: _includeUnused ? theme.primaryColor : theme.shadowColor, height: 1.6)))
                      ],
                    )
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _includeAbiSem = !_includeAbiSem),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.dividerColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Icon(_includeAbiSem ? Icons.check_rounded : Icons.close_rounded, size: 18, color: _includeAbiSem ? theme.primaryColor : theme.shadowColor, weight: 700),
                        Flexible(child: Text("Abiturprüfungen / Seminararbeit", style: theme.textTheme.displayMedium?.copyWith(color: _includeAbiSem ? theme.primaryColor : theme.shadowColor, height: 1.6)))
                      ],
                    )
                ),
              ),
            ],
          ),
          const SizedBox(height: 16,),

          for (int i = 0, placement = 1; i < stats.bestSubjects.length; i++, placement = (stats.bestSubjects[i - 1].$2 == stats.bestSubjects[min(i, stats.bestSubjects.length - 1)].$2 ? placement : placement + 1)) ...[
            const SizedBox(height: 4,),
            _buildTextLine(_buildSubject(theme.textTheme, stats.bestSubjects[i].$1, placement), [
              if (width > 480) Row(children: [
                for (Semester semester in Semester.values)
                  if ((widget.results[stats.bestSubjects[i].$1]?[semester]?.valid ?? false)
                      && (_includeAbiSem || semester.semesterCountEquivalent == 1)
                      && (_includeUnused || (widget.results[stats.bestSubjects[i].$1]?[semester]?.used ?? false))) Container(
                      margin: EdgeInsets.symmetric(horizontal: semester.semesterCountEquivalent > 1 ? 1 : 2),
                      width: 21 + (semester.semesterCountEquivalent > 1 ? 4 : 2),
                      height: 19 + (semester.semesterCountEquivalent > 1 ? 4 : 2),
                      decoration: (widget.results[stats.bestSubjects[i].$1]?[semester]?.used ?? false) ? BoxDecoration(
                        color: semester.semesterCountEquivalent > 1 ? Colors.transparent : theme.primaryColor,
                        border: semester.semesterCountEquivalent > 1 ? Border.all(color: theme.primaryColor, width: 2) : null,
                        borderRadius: BorderRadius.circular(semester.semesterCountEquivalent > 1 ? 6 : 5)
                      ) : null,
                      child: Center(child: Text(widget.results[stats.bestSubjects[i].$1]?[semester]?.effectiveGrade.toString() ?? "-",
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13, fontWeight: semester.semesterCountEquivalent > 1 ? FontWeight.w700 : FontWeight.w600,
                            color: semester.semesterCountEquivalent > 1 ? theme.primaryColor : !(widget.results[stats.bestSubjects[i].$1]?[semester]?.used ?? false) ? theme.primaryColor : theme.scaffoldBackgroundColor),
                        textAlign: TextAlign.center,
                      ))
                  ),
              ]),
              const SizedBox(width: 8),
              Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400)),
              const SizedBox(width: 4),
              Text(GradeHelper.formatNumber(stats.bestSubjects[i].$2, decimals: 2), style: theme.textTheme.bodyMedium),
            ]),
          ]
        ]
    );
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

  Widget _buildSubject(TextTheme textTheme, Subject subject, int place) {
    return Expanded(
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: subject.color),
            width: 26,
            height: 22,
            child: Center(
              child: Text(
                place.toString(),
                style: textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.25, fontWeight: FontWeight.w600, color: subject.color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(subject.name, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,)),
        ],
      ),
    );
  }
}
