import 'package:flutter/material.dart';

import '../widgets/skeleton.dart';
import '../logic/grades.dart';
import '../logic/results.dart';
import '../logic/types.dart';
import '../provider/grades.dart';

class TopSubjectsSubpage extends StatelessWidget {
  const TopSubjectsSubpage({super.key, required this.stats, required this.results});

  final Statistics stats;
  final Map<Subject, Map<Semester, SemesterResult>> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    return SubpageSkeleton(
        title: const PageTitle(title: "Beste Fächer"),
        children: [
          for (int i = 0; i < stats.bestSubjects.length; i++) ...[
            const SizedBox(height: 4,),
            _buildTextLine(_buildSubject(theme.textTheme, stats.bestSubjects[i].$1, i + 1), [
              if (width > 480) Row(children: [
                for (Semester semester in Semester.values)
                  if (!(results[stats.bestSubjects[i].$1]?[semester]?.prediction ?? true)) Container(
                      margin: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                      width: 21,
                      height: 19,
                      decoration: (results[stats.bestSubjects[i].$1]?[semester]?.used ?? false) ? BoxDecoration(color: semester.semesterCountEquivalent > 1 ? theme.shadowColor : theme.primaryColor, borderRadius: BorderRadius.circular(4)) : null,
                      child: Center(child: Text(results[stats.bestSubjects[i].$1]?[semester]?.effectiveGrade.toString() ?? "-",
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: semester.semesterCountEquivalent > 1 ? theme.primaryColor : !(results[stats.bestSubjects[i].$1]?[semester]?.used ?? false) ? theme.primaryColor : theme.scaffoldBackgroundColor),
                        textAlign: TextAlign.center,
                      ))
                  ),
              ]),
              const SizedBox(width: 8),
              Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
              const SizedBox(width: 4),
              Text("${GradeHelper.formatNumber(stats.bestSubjects[i].$2, decimals: 2)}", style: theme.textTheme.bodyMedium),
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
            height: 23,
            child: Text(
              place.toString(),
              style: textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.66, fontWeight: FontWeight.w600, color: subject.color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(subject.name, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,)),
        ],
      ),
    );
  }
}
