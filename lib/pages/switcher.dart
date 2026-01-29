import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/grades.dart';
import '../widgets/skeleton.dart';
import '../widgets/subpage.dart';

// clicked semester via subpage callback result
class SemesterSwitcherPage extends StatelessWidget {
  const SemesterSwitcherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradesProvider = Provider.of<GradesDataProvider>(context, listen: false);

    return IntrinsicHeight(
      child: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.3),
        color: theme.cardColor,
        padding: const EdgeInsets.symmetric(horizontal: PageSkeleton.leftOffset, vertical: 20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildSemester(context, theme, Semester.q12_1, gradesProvider.currentSemester),
              const SizedBox(width: 16,),
              _buildSemester(context, theme, Semester.q12_2, gradesProvider.currentSemester),
            ]),
            const SizedBox(height: 12,),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildSemester(context, theme, Semester.q13_1, gradesProvider.currentSemester),
              const SizedBox(width: 16,),
              _buildSemester(context, theme, Semester.q13_2, gradesProvider.currentSemester),
            ]),
            const SizedBox(height: 12,),
            _buildSemester(context, theme, Semester.abi, gradesProvider.currentSemester),
          ],
        )
      ),
    );
  }

  Widget _buildSemester(BuildContext context, ThemeData theme, Semester semester, Semester? currentSemester) {
    return Flexible(
      flex: 1,
      child: GestureDetector(
        onTap: () => SubpageController.of(context).closeSubpage(semester),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.fromBorderSide(BorderSide(
              color: semester == currentSemester ? theme.primaryColor : theme.dividerColor,
              width: 2.5,
            )),
            color: semester == currentSemester ? theme.primaryColor : null,
          ),
          padding: const EdgeInsets.all(5),
          child: Text(semester.detailedDisplay, style: (semester == currentSemester ? theme.textTheme.labelMedium : theme.textTheme.labelSmall)?.copyWith(fontSize: 16), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
