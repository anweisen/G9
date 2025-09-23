import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../provider/settings.dart';
import '../provider/grades.dart';
import '../logic/grades.dart';
import '../logic/types.dart';
import '../widgets/skeleton.dart';
import '../widgets/subpage.dart';
import 'grade.dart';

class SubjectPage extends StatefulWidget {
  final Subject subject;

  const SubjectPage({super.key, required this.subject});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {

  Semester? _currentSemester;

  @override
  void initState() {
    super.initState();
    final originalSemester = Provider.of<GradesDataProvider>(context, listen: false).currentSemester;
    _currentSemester ??= Semester.mapSemesterToDisplaySemester(originalSemester, widget.subject.category);
  }

  void setCurrentSemester(Semester semester) {
    Provider.of<GradesDataProvider>(context, listen: false).currentSemester = semester;
    setState(() {
      _currentSemester = semester;
    });
  }

  void setCurrentSemesterTranslated(Semester semester) {
    final provider = Provider.of<GradesDataProvider>(context, listen: false);
    if (semester == Semester.seminar13 && !(provider.currentSemester == Semester.q13_1 || provider.currentSemester == Semester.q13_2)) {
      provider.currentSemester = Semester.q13_1;
    }

    setState(() {
      _currentSemester = semester;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double leftOffset = PageSkeleton.leftOffset;
    final ThemeData theme = Theme.of(context);
    final Choice? choice = Provider.of<SettingsDataProvider>(context).choice;
    final GradesDataProvider dataProvider = Provider.of<GradesDataProvider>(context);
    final grades = dataProvider.getGrades(widget.subject.id, semester: _currentSemester);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: leftOffset),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: widget.subject.color),
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 16),
              Expanded(flex: 100, child: Text(widget.subject.name, softWrap: false, overflow: TextOverflow.ellipsis, maxLines: 2, style: theme.textTheme.headlineMedium)),
              const Spacer(),
              SvgPicture.asset(
                "assets/svg/average.svg",
                width: 20,
                colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(GradeHelper.formatAverage(grades, decimals: 2), style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: leftOffset),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: theme.primaryColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSemester(theme, dataProvider, choice, _currentSemester!, Semester.q12_1, setCurrentSemester),
                  _buildSemester(theme, dataProvider, choice, _currentSemester!, Semester.q12_2, setCurrentSemester),
                  if (widget.subject.category == SubjectCategory.seminar) ...[
                    _buildSemester(theme, dataProvider, choice, _currentSemester!, Semester.seminar13, setCurrentSemesterTranslated),
                  ] else ...[
                    _buildSemester(theme, dataProvider, choice, _currentSemester!, Semester.q13_1, setCurrentSemester),
                    _buildSemester(theme, dataProvider, choice, _currentSemester!, Semester.q13_2, setCurrentSemester),
                  ],
                ],
              )),
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: leftOffset),
          child: Row(
            children: [
              Text("Noten", style: theme.textTheme.headlineMedium),
              const Spacer(),
              GestureDetector(
                  onTap: () => SubpageController.of(context).openSubpage(
                      GradePage(subject: widget.subject, key: GlobalKey(), semester: _currentSemester!,),
                      callback: (result) => {
                        if (result is GradeEditResult) {
                          _addGrade(dataProvider, result)
                        }
                      }),
                  child: Icon(Icons.add, color: theme.primaryColor, size: 30)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
              itemCount: grades.length,
              itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: leftOffset),
                  child: TestItem(theme: theme, entry: grades[index], subject: widget.subject,
                  callback: (result) {
                    if (result is GradeEditResult) {
                      _removeGrade(dataProvider, index);
                      if (!result.remove) _addGrade(dataProvider, result);
                    }
                  }, semester: _currentSemester!,))),
        ),
      ]),
    );
  }

  void _removeGrade(GradesDataProvider dataProvider, int index) {
    dataProvider.removeGrade(widget.subject.id, index, semester: _currentSemester);

    if (widget.subject.category == SubjectCategory.seminar) {
      if (_currentSemester == Semester.q13_1) {
        dataProvider.removeGrade(widget.subject.id, index, semester: Semester.q13_2);
      } else if (_currentSemester == Semester.q13_2) {
        dataProvider.removeGrade(widget.subject.id, index, semester: Semester.q13_1);
      }
    }
  }

  void _addGrade(GradesDataProvider dataProvider, GradeEditResult result) {
    dataProvider.addGrade(result.subject.id, result.entry, semester: _currentSemester);

    if (result.subject.category == SubjectCategory.seminar) {
      if (_currentSemester == Semester.q13_1) {
        dataProvider.addGrade(result.subject.id, result.entry, semester: Semester.q13_2);
      } else if (_currentSemester == Semester.q13_2) {
        dataProvider.addGrade(result.subject.id, result.entry, semester: Semester.q13_1);
      }
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.type.name, style: theme.textTheme.bodyMedium),
                Text(GradeHelper.formatDate(entry.date), style: theme.textTheme.bodySmall),
              ],
            ),
            const Spacer(),
            Text(entry.grade.toString(), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
