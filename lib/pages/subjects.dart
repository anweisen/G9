import 'package:abi_app/logic/results.dart';

import '../logic/grades.dart';
import '../provider/grades.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../provider/settings.dart';
import '../logic/types.dart';
import '../widgets/nav.dart';
import '../widgets/subpage.dart';
import 'subject.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const double leftOffset = 36;
    final ThemeData theme = Theme.of(context);
    final settings = Provider.of<SettingsDataProvider>(context);
    final grades = Provider.of<GradesDataProvider>(context).getGradesForSemester(settings.choice!);

    final avg = GradeHelper.averageOfSubject(grades);

    print("Building subjects page with choice: ${settings.choice}");

    return SubpageController(
      child: Scaffold(
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
                      Text("Fächer", style: theme.textTheme.headlineMedium),
                      Row(
                          verticalDirection: VerticalDirection.down,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text("Ø", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w300, fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(GradeHelper.formatNumber(avg), style: theme.textTheme.headlineMedium),
                          const SizedBox(width: 8),
                          Text("(${GradeHelper.formatNumber(SemesterResult.convertAverage(avg))})", style: theme.textTheme.bodySmall),
                        ]
                      )
                    ],
                  ),
                ),


                if (Provider.of<SettingsDataProvider>(context).choice != null)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
                      itemCount: Provider.of<SettingsDataProvider>(context).choice!.subjects.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: leftOffset, vertical: 10),
                        child: SubjectWidget(subject: Provider.of<SettingsDataProvider>(context).choice!.subjects[index]),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
        bottomNavigationBar: const Nav(),
        extendBody: true,
      ),
    );
  }
}

class SubjectWidget extends StatelessWidget {
  final Subject subject;

  const SubjectWidget({
    super.key, required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final grades = Provider.of<GradesDataProvider>(context).getGrades(subject.id);

    final Color contrastColor = subject.color.computeLuminance() > 0.80 ? (theme.brightness == Brightness.light ? Colors.black : Colors.black87) : Colors.white;

    return GestureDetector(
      onTap: () => SubpageController.of(context).openSubpage(SubjectPage(subject: subject, key: GlobalKey(),)),
      child: Container(
        decoration: BoxDecoration(
          color: subject.color.withAlpha(theme.brightness == Brightness.dark ? 150 : 166),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Stack(
                alignment: Alignment.center,
                children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: subject.color,
                ),
                width: 36,
                height: 22,
              ),
              Center(child: Text(GradeHelper.formatAverage(grades), style: TextStyle(color: contrastColor, fontSize: 13, fontWeight: FontWeight.w500))),
            ]),
            const SizedBox(width: 10),
            Text(subject.name, style: theme.textTheme.labelMedium?.copyWith(color: contrastColor), maxLines: 1, overflow: TextOverflow.clip),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
