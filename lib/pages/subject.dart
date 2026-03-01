import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/results.dart';
import '../logic/choice.dart';
import '../provider/account.dart';
import '../provider/settings.dart';
import '../provider/grades.dart';
import '../logic/grades.dart';
import '../logic/types.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../widgets/subpage.dart';
import 'development.dart';
import 'grade.dart';
import 'result.dart';
import 'weighting.dart';

class SubjectPage extends StatefulWidget {
  final Subject subject;
  final Semester? semester;

  const SubjectPage({super.key, required this.subject, this.semester});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {

  Semester? _currentSemester;

  @override
  void initState() {
    super.initState();
    final originalSemester = widget.semester ?? Provider.of<GradesDataProvider>(context, listen: false).currentSemester;
    _currentSemester ??= Semester.mapSemesterToDisplaySemester(originalSemester, widget.subject.category);
  }

  void setCurrentSemester(Semester semester) {
    // TODO extract
    final gradesProvider = Provider.of<GradesDataProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountDataProvider>(context, listen: false);
    if (semester == Semester.seminar13 && !(gradesProvider.currentSemester == Semester.q13_1 || gradesProvider.currentSemester == Semester.q13_2)) {
      gradesProvider.changeCurrentSemester(Semester.q13_1);
      accountProvider.updateSemester(Semester.q13_1);
    } else {
      gradesProvider.changeCurrentSemester(semester);
      accountProvider.updateSemester(semester);
    }

    setState(() {
      _currentSemester = semester;
    });
  }

  void openResultPage() {
    final choice = Provider.of<SettingsDataProvider>(context, listen: false).choice;
    final dataProvider = Provider.of<GradesDataProvider>(context, listen: false);
    final results = SemesterResult.calculateResultsWithPredictions(choice!, dataProvider);
    final _ = SemesterResult.applyUseFlags(choice, results);
    SubpageController.of(context).openSubpage(SubjectResultPage(subject: widget.subject, results: results[widget.subject]!, choice: choice, key: GlobalKey(),));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Choice? choice = Provider.of<SettingsDataProvider>(context).choice;
    final GradesDataProvider dataProvider = Provider.of<GradesDataProvider>(context);
    final AccountDataProvider accountProvider = Provider.of<AccountDataProvider>(context);
    final GradesList grades = dataProvider.getGrades(widget.subject.id, semester: _currentSemester);

    return SubpageSkeleton(
        title: Row(
          children: [
            SubjectPageTitle(subject: widget.subject),
            const Spacer(),

            const SizedBox(width: 12),
            Text("Ø", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w300, fontSize: 22)),
            const SizedBox(width: 6),
            Text(GradeHelper.formatSemesterAverage(grades, decimals: (_currentSemester!.semesterCountEquivalent > 1 ? 1 : 2)), style: theme.textTheme.headlineMedium),
            if (_currentSemester!.semesterCountEquivalent > 1) ...[
              const SizedBox(width: 6),
              Text("(≈ ", style: theme.textTheme.labelSmall),
              Text(GradeHelper.formatSemesterAverage(grades, decimals: 1, semesterCountEquivalent: _currentSemester!.semesterCountEquivalent), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(")", style: theme.textTheme.labelSmall),
            ]
          ],
        ),
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: theme.primaryColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (Semester semester in Semester.qPhaseEquivalents(widget.subject.category))
                    _buildSemester(theme, dataProvider, choice, _currentSemester!, semester, setCurrentSemester)
                ],
              )
          ),
          const SizedBox(height: 36),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // align info text left
            children: [
              Row(
                children: [
                  Text("Noten", style: theme.textTheme.headlineMedium),
                  const SizedBox(width: 8),
                  SubpageTrigger(
                      createSubpage: () => WeightingPage(subject: widget.subject, semester: _currentSemester!,),
                      child: const Icon(Icons.help_outline_rounded, size: 20),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: openResultPage,
                      child: const Icon(Icons.insert_chart_outlined_rounded, size: 20),
                  ),
                  const SizedBox(width: 8),
                  SubpageTrigger(
                    createSubpage: () => GradesDevelopmentPage(subject: widget.subject,),
                      child: const Icon(Icons.timeline, size: 20),
                  ),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => SubpageController.of(context).openSubpage(
                          GradePage(subject: widget.subject, key: GlobalKey(), semester: _currentSemester!,),
                          callback: (result) {
                            if (result is GradeEditResult) {
                              _addGrade(dataProvider, result);
                              accountProvider.updateSubjectGradesFromResult(result, dataProvider);
                            }
                          }),
                      child: Icon(Icons.add, color: theme.primaryColor, size: 30)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          if ((grades.isEmpty || grades.length == 1 && grades.first.type == GradeType.result) && (_currentSemester == Semester.seminar13 || _currentSemester == Semester.abi))
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32,),
                ..._buildDirectSelection(theme, grades.firstOrNull, accountProvider, dataProvider)
              ],
            )
          else for (int index = 0; index < grades.length; index++)
            if (grades[index].type != GradeType.result) TestItem(theme: theme,
              entry: grades[index],
              subject: widget.subject,
              semester: _currentSemester!,
              callback: (result) {
                if (result is GradeEditResult) {
                  _removeGrade(dataProvider, index);
                  if (!result.remove) _addGrade(dataProvider, result);
                  accountProvider.updateSubjectGradesFromResult(result, dataProvider);
                }
              },
            ),
    ]);
  }

  void _removeGrade(GradesDataProvider dataProvider, int index) {
    dataProvider.removeGrade(widget.subject.id, index, semester: _currentSemester); // result.semester?
  }

  void _addGrade(GradesDataProvider dataProvider, GradeEditResult result) {
    dataProvider.addGrade(result.subject.id, result.entry, semester: result.semester);
  }

  List<Widget> _buildDirectSelection(ThemeData theme, GradeEntry? grade, AccountDataProvider accountProvider, GradesDataProvider gradesProvider) {
    return [
      Text("oder direkt Ergebnis eintragen", style: theme.textTheme.displayMedium?.copyWith(fontStyle: FontStyle.italic)),
      const SizedBox(height: 8,),

      if (grade != null) Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  final entry = GradeEntry(min(max(grade.grade - 1, 0), 15 * _currentSemester!.semesterCountEquivalent), GradeType.result, DateTime.now());
                  final result = GradeEditResult(entry, widget.subject, _currentSemester!, true);
                  _removeGrade(gradesProvider, 0);
                  _addGrade(gradesProvider, result);
                  accountProvider.updateSubjectGradesFromResult(result, gradesProvider);
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: grade.grade <= 0 ? Colors.transparent : theme.textTheme.labelSmall!.color!, width: 1.5))),
                    child: Icon(Icons.remove_rounded, size: 16, color: grade.grade <= 0 ? Colors.transparent : theme.textTheme.labelSmall?.color)
                ),
              ),
              const SizedBox(width: 12,),
              SizedBox(
                  width: 32,
                  child: Text(grade.grade.toString(), style: theme.textTheme.headlineMedium, textAlign: TextAlign.center,)
              ),
              const SizedBox(width: 12,),
              GestureDetector(
                onTap: () {
                  final entry = GradeEntry(min(max(grade.grade + 1, 0), 15 * _currentSemester!.semesterCountEquivalent), GradeType.result, DateTime.now());
                  final result = GradeEditResult(entry, widget.subject, _currentSemester!, true);
                  _removeGrade(gradesProvider, 0);
                  _addGrade(gradesProvider, result);
                  accountProvider.updateSubjectGradesFromResult(result, gradesProvider);
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: grade.grade >= 15 * _currentSemester!.semesterCountEquivalent ? Colors.transparent : theme.textTheme.labelSmall!.color!, width: 1.5))),
                    child: Icon(Icons.add_rounded, size: 16, color: grade.grade >= 15 * _currentSemester!.semesterCountEquivalent ? Colors.transparent : theme.textTheme.labelSmall?.color)
                ),
              ),
            ],
          ),
          const SizedBox(height: 8,),
          GestureDetector(
            onTap: () {
              _removeGrade(gradesProvider, 0);
              accountProvider.updateSubjectGrades(widget.subject.id, _currentSemester!, gradesProvider);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: theme.dividerColor, width: 2))),
              child: Text("Ergebnis löschen", style: theme.textTheme.displayMedium?.copyWith(height: 1.25), softWrap: true, maxLines: 2,),
            ),
          ),
        ],
      ) else GestureDetector(
        onTap: () {
          final settingsProvider = Provider.of<SettingsDataProvider>(context, listen: false);
          final results = SemesterResult.calculateResultsWithPredictions(settingsProvider.choice!, gradesProvider);
          final _ = SemesterResult.applyUseFlags(settingsProvider.choice!, results);
          final result = GradeEditResult(GradeEntry(SemesterResult.calculatePrediction(null, results) * _currentSemester!.semesterCountEquivalent, GradeType.result, DateTime.now()), widget.subject, _currentSemester!, false);
          _addGrade(gradesProvider, result);
          accountProvider.updateSubjectGradesFromResult(result, gradesProvider);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.fromBorderSide(BorderSide(color: theme.dividerColor, width: 2))),
          child: Text("Ergebnis eintragen", style: theme.textTheme.displayMedium?.copyWith(height: 1.25, color: theme.primaryColor), softWrap: true, maxLines: 2,),
        ),
      )
    ];
  }

  Widget _buildSemester(ThemeData theme, GradesDataProvider dataProvider, Choice? choice, Semester currentSemester, Semester semester, void Function(Semester) callback) {
    final grades = dataProvider.getGrades(widget.subject.id, semester: semester);
    final bool selected = currentSemester == semester;

    return GestureDetector(
      onTap: () => {
        if (choice!.hasSubjectInSemester(widget.subject, semester)) {
          callback(semester)
        }
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: selected ? theme.scaffoldBackgroundColor : null,
          ),
          child: Column(children: [
            Text(semester.display, style: theme.textTheme.bodySmall),
            Text(grades.isEmpty ? "-" : GradeHelper.result(grades).toString(), style: theme.textTheme.labelMedium?.copyWith(color: selected ? theme.primaryColor : null)),
          ]),
        ),
      ),
    );
  }
}

class TestItem extends StatelessWidget {
  const TestItem({
    super.key,
    required this.theme, required this.entry, required this.subject, required this.callback, required this.semester,
  });

  final Semester semester;
  final Subject subject;
  final GradeEntry entry;
  final ThemeData theme;
  final void Function(dynamic result) callback;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SubpageController.of(context).openSubpage(GradePage(subject: subject, entry: entry, semester: semester, key: GlobalKey(),), callback: callback),
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, (entry.type == GradeType.klausur || entry.type == GradeType.seminar) ? 25 : 10),
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(entry.type.name, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1), maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(GradeHelper.formatDate(entry.date), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Spacer(),
            Text(entry.grade.toString(), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
