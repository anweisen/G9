import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/results.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../logic/grades.dart';
import '../logic/types.dart';
import '../widgets/skeleton.dart';
import '../widgets/subpage.dart';

// (!) USE A GLOBAL KEY
class GradePage extends StatefulWidget {
  const GradePage({super.key, this.subject, this.entry, required this.semester});

  final Semester semester;
  final Subject? subject;
  final GradeEntry? entry;

  @override
  State<GradePage> createState() => _GradePageState();
}

class _GradePageState extends State<GradePage> with AutomaticKeepAliveClientMixin {

  Subject? _subject;
  Semester? _semester;

  int? _grade;
  GradeType? _type;
  DateTime? _date;

  late bool _usesSlider;

  @override
  void initState() {
    super.initState();

    final gradesProvider = Provider.of<SettingsDataProvider>(context, listen: false);

    _subject = widget.subject;
    _semester = widget.semester;
    _grade = widget.entry?.grade;
    _type = widget.entry?.type;
    _date = widget.entry?.date ?? DateTime.now();
    _usesSlider = gradesProvider.usesSlider ?? kIsWeb;

    final choice = gradesProvider.choice;
    if (choice != null) {
      final results = SemesterResult.calculateResultsWithPredictions(choice, Provider.of<GradesDataProvider>(context, listen: false));
      _grade = SemesterResult.calculatePrediction(_subject, results);
    }
  }

  GradeEntry get entry => GradeEntry(_grade!, _type!, _date!);

  bool get isValid => _grade != null && _type != null && _date != null && _subject != null && _semester != null;

  bool get isFromExisting => widget.entry != null && widget.subject != null;

  void setGrade(int grade) {
    setState(() {
      _grade = grade;
    });
  }

  void setSemester(Semester semester) {
    // reset type if not valid anymore
    if (_type != null && _subject != null) {
      final choice = Provider.of<SettingsDataProvider>(context, listen: false).choice!;
      final possibleTypes = GradeType.types(choice, _subject!, semester);
      if (!possibleTypes.contains(_type)) {
        _type = null;
      }
    }

    setState(() {
      _semester = semester;
      _type = _type;
    });
  }

  void setSubject(Subject subject) {
    // reset type if not valid anymore
    if (_type != null) {
      final choice = Provider.of<SettingsDataProvider>(context, listen: false).choice!;
      final possibleTypes = GradeType.types(choice, subject, _semester!);
      if (!possibleTypes.contains(_type)) {
        _type = null;
      }
    }
    // reset semester if not valid anymore
    if (_semester != null) {
      final choice = Provider.of<SettingsDataProvider>(context, listen: false).choice!;
      if (!choice.hasSubjectInSemester(subject, _semester!)) {
        _semester = null;
      }
    }

    setState(() {
      _subject = subject;
      _semester = _semester;
      _type = _type;
    });
  }

  void setType(GradeType type) {
    setState(() {
      _type = type;
    });
  }

  void setDate(DateTime date) {
    setState(() {
      _date = date;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);

    return SubpageSkeleton(
      title: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text("Note ${isFromExisting ? "ändern" : "hinzufügen"}", style: theme.textTheme.headlineMedium),
        const Spacer(),

        GestureDetector(
          child: Icon(!_usesSlider ? Icons.tune_rounded : Icons.grid_view_rounded, color: theme.primaryColor, size: 22,),
          onTap: () => setState(() {
            _usesSlider = Provider.of<SettingsDataProvider>(context, listen: false).usesSlider = !_usesSlider;
          }),
        )
      ]),
      actions: [
        if (_usesSlider)
          Positioned(
            bottom: 24 + PageSkeleton.leftOffset + 66,
            left: PageSkeleton.leftOffset,
            right: PageSkeleton.leftOffset,
            child: GradeSlider(grade: _grade, onGradeChanged: setGrade),
          ),

        SaveButtonContainer(
          btn1: SaveButton(
            onTap: () {
              if (isValid) {
                SubpageController.of(context).closeSubpage(GradeEditResult(entry, _subject!, _semester!, false));
              }
            },
            shown: isValid,
            index: 0,
            icon: Icons.chevron_right_rounded,
            text: "Speichern",
          ),
          btn2: isFromExisting ? SaveButton(
            onTap: () {
              if (isValid) {
                SubpageController.of(context).closeSubpage(GradeEditResult(entry, _subject!, _semester!, true));
              }
            },
            shown: true,
            index: 1,
            icon: Icons.delete_forever,
            text: "Löschen",
          ) : null, shown: true,)
      ],
      children: [
        Stack(
          children: [
            Column(children: [
              if (!_usesSlider) ...[
                GradeGrid(grade: _grade, onGradeChanged: setGrade),
                const SizedBox(height: 32),
              ],

              // Subject
              SubpageTrigger(
                createSubpage: () => SubjectSelectionPage(semester: _semester, subject: _subject),
                callback: (subject) {
                  if (subject is Subject) setSubject(subject);
                },
                child: (_subject == null)
                    ? const GradeOptionPlaceholder(text: "Wähle ein Fach")
                    : GradeOptionPlaceholder(
                        text: _subject!.name,
                        icon: Container(height: 22, width: 22, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _subject!.color),)
                ),
              ),

              // Semester
              const SizedBox(height: 14),
              SubpageTrigger(
                createSubpage: () => SemesterSelectionPage(subject: _subject),
                callback: (semester) {
                  if (semester is Semester) setSemester(semester);
                },
                child: (_semester == null)
                    ? const GradeOptionPlaceholder(text: "Wähle ein Semester")
                    : GradeOptionPlaceholder(
                      text: _semester!.detailedDisplay,
                      icon: Icon(Icons.account_tree_rounded, color: theme.primaryColor, size: 24),)
                ),

              // GradeType
              // on subject/semester change: reset GradeType if needed
              const SizedBox(height: 14),
              SubpageTrigger(
                  createSubpage: () => GradeTypSelectionPage(semester: _semester, subject: _subject, originalType: _type),
                  callback: (type) => {
                    if (type is GradeType) setType(type)
                  },
                  child: (_type == null)
                      ? const GradeOptionPlaceholder(text: "Wähle eine Prüfungsart")
                      : GradeOptionPlaceholder(
                          text: _type!.name,
                          icon: Icon(Icons.label_rounded, color: theme.primaryColor, size: 24))),

              // Date
              const SizedBox(height: 14),
              if (_date == null)
                const GradeOptionPlaceholder(text: "Wähle ein Datum")
              else
                GradeOptionPlaceholder(
                    text: GradeHelper.formatDate(_date!),
                    icon: Icon(Icons.calendar_month_rounded, color: theme.primaryColor, size: 24)),
            ]),
          ],
        )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class GradeOptionPlaceholder extends StatelessWidget {
  const GradeOptionPlaceholder({super.key, required this.text, this.icon, this.textColor});

  final Color? textColor;
  final String text;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) icon!
        else Icon(Icons.add_circle_rounded, color: theme.textTheme.bodySmall?.color, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(text, softWrap: false, overflow: TextOverflow.ellipsis, maxLines: 2, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor ?? (icon == null ? theme.textTheme.bodySmall?.color : null)))),
      ],
    );
  }
}
class GradeOptionPlaceholderIcon extends StatelessWidget {
  const GradeOptionPlaceholderIcon({super.key, required this.text, required this.icon, this.textColor});

  final Color? textColor;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GradeOptionPlaceholder(text: text, icon: Icon(icon, color: textColor ?? theme.primaryColor, size: 24), textColor: textColor);
  }
}

class GradeTypSelectionPage extends StatelessWidget {
  const GradeTypSelectionPage({super.key, required this.semester, this.subject, this.originalType});

  final Semester? semester;
  final Subject? subject;
  final GradeType? originalType;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final choice = Provider.of<SettingsDataProvider>(context).choice!;
    final grades = subject != null ? Provider.of<GradesDataProvider>(context).getGrades(subject!.id, semester: semester) : List<GradeEntry>.empty();
    final existingTypes = grades.map((e) => e.type).toList();
    // only remove one!
    for (int i = 0; i < existingTypes.length; i++) {
      if (existingTypes[i] == originalType) {
        existingTypes.removeAt(i);
        break;
      }
    }
    final List<GradeType> types = (subject != null && semester != null) ? GradeType.types(choice, subject!, semester!) : GradeType.values;
    final Set<GradeTypeArea> areas = types.map((e) => e.area).toSet();

    return SubpageSkeleton(
        title: Text("Prüfungsart wählen", style: theme.textTheme.headlineMedium),
        children: [
          for (int index = 0; index < types.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: GestureDetector(
                onTap:  () => {
                  if (types[index].stillPossible(existingTypes)) {
                    SubpageController.of(context).closeSubpage(types[index])
                  }
                },
                child: Padding(
                  padding: (index > 0 && types[index - 1].area != types[index].area)
                      ? const EdgeInsets.only(top: 12)
                      : const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      if (areas.length > 1 && (index > 0 ? types[index - 1].area != types[index].area : GradeType.only(types[index].area).length > 1)) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            types[index].area.name,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 8,)
                      ],

                      GradeOptionPlaceholderIcon(
                          textColor: types[index].stillPossible(existingTypes) ? null : theme.textTheme.bodySmall?.color,
                          text: types[index].name,
                          icon: getIcon(types[index])),
                    ],
                  ),
                ),
              ),
            )

    ]);
  }

  static IconData getIcon(GradeType type) {
    switch (type) {
      case GradeType.klausur:
        return Icons.school_rounded;
      case GradeType.referat:
        return Icons.assignment_rounded;
      case GradeType.test:
        return Icons.edit_rounded;
      case GradeType.ausfrage:
        return Icons.question_answer_rounded;
      case GradeType.mitarbeit:
        return Icons.emoji_people_rounded;
      case GradeType.praxis:
        return Icons.sports_soccer_rounded;
      case GradeType.technik:
        return Icons.build_rounded;
      case GradeType.theorie:
        return Icons.menu_book_rounded;
      case GradeType.seminar:
        return Icons.bookmark_outlined;
      case GradeType.seminarreferat:
        return Icons.question_answer_rounded;
      case GradeType.schriftlich:
        return Icons.article_rounded;
      case GradeType.muendlich:
        return Icons.speaker_notes_rounded;
      case GradeType.zusatz:
        return Icons.mic_rounded;
      case GradeType.fach:
        return Icons.architecture_rounded;
      case GradeType.kunstprojekt:
        return Icons.palette_rounded;
      case GradeType.musikpruefung:
        return Icons.piano_rounded;
      default:
        return Icons.label_rounded; // Fallback icon
    }
  }
}

class SubjectSelectionPage extends StatelessWidget {
  const SubjectSelectionPage({super.key, required this.semester, this.subject});

  final Semester? semester;
  final Subject? subject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final choice = Provider.of<SettingsDataProvider>(context).choice!;
    final subjects = choice.subjectsToDisplayForSemester(semester ?? Semester.q12_1);

    return SubpageSkeleton(
        title: Text("Fach wählen", style: theme.textTheme.headlineMedium),
        children: [
          for (int index = 0; index < subjects.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: GestureDetector(
                onTap: () => SubpageController.of(context).closeSubpage(subjects[index]),
                child: GradeOptionPlaceholder(
                    text: subjects[index].name,
                    icon: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: subjects[index].color),)
                ),
              ),
            )

        ]);
  }
}

class SemesterSelectionPage extends StatelessWidget {
  const SemesterSelectionPage({super.key, required this.subject});

  final Subject? subject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final choice = Provider.of<SettingsDataProvider>(context).choice!;
    final semesters = subject != null ? choice.getSemestersForSubject(subject!) : Semester.qPhase;

    return SubpageSkeleton(
        title: Text("Semester wählen", style: theme.textTheme.headlineMedium),
        children: [
          for (int index = 0; index < semesters.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: GestureDetector(
                onTap: () => SubpageController.of(context).closeSubpage(semesters[index]),
                child: GradeOptionPlaceholderIcon(
                    text: semesters[index].detailedDisplay,
                    icon: getIcon(semesters[index]))
                ),
              ),
        ]);
  }

  static IconData getIcon(Semester semester) {
    return switch (semester) {
      Semester.q12_1 => Icons.looks_one_rounded,
      Semester.q12_2 => Icons.looks_two_rounded,
      Semester.q13_1 => Icons.looks_3_rounded,
      Semester.q13_2 => Icons.looks_4_rounded,
      Semester.seminar13 => Icons.article_rounded,
      Semester.abi => Icons.school_rounded,
      _ => Icons.account_tree_rounded,
    };
  }
}

class SaveButtonContainer extends StatelessWidget {
  const SaveButtonContainer({super.key, required this.btn1, required this.btn2, required this.shown});

  final SaveButton? btn1, btn2;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24 + PageSkeleton.leftOffset,
      left: PageSkeleton.leftOffset,
      right: PageSkeleton.leftOffset,
      child: Row(
        children: _buildContent(),
      ),
    );
  }

  List<Widget> _buildContent() {
    if ((btn1?.shown ?? false) && (btn2?.shown ?? false)) {
      return [btn1!, const SizedBox(width: 10), btn2!];
    } else if (btn1?.shown ?? false) {
      return [btn1!];
    } else if (btn2?.shown ?? false) {
      return [btn2!];
    } else {
      return const [];
    }
  }
}


class SaveButton extends StatelessWidget {
  const SaveButton({super.key,
    required this.shown,
    required this.onTap,
    required this.index, required this.icon, required this.text});

  final int index;
  final bool shown;
  final Function() onTap;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: theme.primaryColor),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(text, style: theme.textTheme.labelMedium),
                  Icon(icon, color: theme.textTheme.labelMedium?.color, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradeGrid extends StatelessWidget {
  const GradeGrid({super.key, required this.grade, required this.onGradeChanged});

  final int? grade;
  final Function(int) onGradeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 4 * (28 + 10), // height + spacing*2
      child: Column(
          children: [
            for (int indexI = 0; indexI < 4; indexI++)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int indexJ = 4 * indexI; indexJ < 4 * indexI + 4; indexJ++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: GestureDetector(
                        onTap: () => onGradeChanged(15 - indexJ),
                        child: _buildGradeButton(indexJ, theme, grade),
                      ),
                    ),
                ],
              ),
          ]
      ),
    );
  }

  Widget _buildGradeButton(int index, ThemeData theme, int? selectedGrade) {
    final int grade = 15 - index;
    return Container(
      width: 48,
      height: 28,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selectedGrade == grade ? theme.primaryColor : theme.cardColor),
      child: Center(
        child: Text(
          grade.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: selectedGrade == grade ? theme.scaffoldBackgroundColor : theme.primaryColor),
        ),
      ),
    );
  }
}


class GradeSlider extends StatefulWidget {
  const GradeSlider({super.key, required this.grade, required this.onGradeChanged});

  final int? grade;
  final Function(int) onGradeChanged;

  @override
  State<GradeSlider> createState() => _GradeSliderState();
}

class _GradeSliderState extends State<GradeSlider> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    if (widget.grade != null) {
      final target = (widget.grade!) / 16.0 + (1 / 16) / 2;
      _controller.value = target;
    } else {
      _controller.value = 0.5;
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateTargetForGrade(int grade) {
    return (grade + 1) / 16.0 - (1 / 16) / 2;
  }

  void _handleDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    _controller.value += (details.primaryDelta ?? 0) / 550;

    for (int i = 0; i <= 15; i++) {
      final target = _calculateTargetForGrade(i);
      final distance = (target - _controller.value).abs();
      if (distance < (1.0 / 16.0) / 2) {
        widget.onGradeChanged(i);
      }
    }
  }

  void _handleDragEnd(DragEndDetails details, BoxConstraints constraints) {
    for (int i = 0; i <= 15; i++) {
      final target = _calculateTargetForGrade(i);
      final distance = (target - _controller.value - (details.velocity.pixelsPerSecond.dx / constraints.maxWidth / 16 / 2)).abs();
      if (distance < (1.0 / 16.0) / 2) {
        widget.onGradeChanged(i);
        _controller.animateTo(target, duration: const Duration(milliseconds: 300));
        return;
      }
    }
    if (_controller.value < _calculateTargetForGrade(0)) {
      _controller.animateTo(_calculateTargetForGrade(0), duration: const Duration(milliseconds: 200));
    }
    if (_controller.value > _calculateTargetForGrade(15)) {
      _controller.animateTo(_calculateTargetForGrade(15), duration: const Duration(milliseconds: 200));
    }
  }

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    if (widget.grade == null) return;

    final localPosition = details.localPosition;
    final relativePosition = localPosition.dx / constraints.maxWidth;

    if (relativePosition > 0.5 && widget.grade! > 0) {
      _controller.animateTo(_calculateTargetForGrade(widget.grade! - 1), duration: const Duration(milliseconds: 150));
      Future.delayed(const Duration(milliseconds: 75), () {
        widget.onGradeChanged(widget.grade! - 1);
      });
    }
    if (relativePosition < 0.5 && widget.grade! < 15) {
      _controller.animateTo(_calculateTargetForGrade(widget.grade! + 1), duration: const Duration(milliseconds: 150));
      Future.delayed(const Duration(milliseconds: 75), () {
        widget.onGradeChanged(widget.grade! + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
          onHorizontalDragUpdate: (details) => _handleDragUpdate(details, constraints),
          onHorizontalDragEnd: (details) => _handleDragEnd(details, constraints),
          onTapDown: (details) => _handleTapDown(details, constraints),
          child: Container(
            width: constraints.maxWidth,
            height: 80,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ClipRect(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, snapshot) => OverflowBox(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                          offset: Offset(constraints.maxWidth / 2 + (16*(44+40)/2 * -(1-_animation.value)) , 0),
                          child: SizedBox(
                            width: 16*(44+40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (int i = 15; i >= 0; i--)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 20),
                                        width: 44,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: (widget.grade == i) ? theme.primaryColor : Colors.transparent,
                                        ),
                                        child: Text(i.toString(),
                                          style: (widget.grade == i) ? theme.textTheme.labelMedium : theme.textTheme.labelSmall,
                                          textAlign: TextAlign.center,
                                        )
                                      ),
                                      const SizedBox(height: 8),
                                      Text(SemesterResult.getDefaultGradeForPoints(i),
                                        style: theme.textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      )
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                    )
                  ),
                ),

                Transform.translate(
                  offset: Offset(constraints.maxWidth / 2 - 50, 7),
                  child: Container(
                    width: 100,
                    height: 63,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                          colors: [
                            theme.dividerColor,
                            theme.dividerColor,
                            theme.dividerColor.withOpacity(0),
                            theme.dividerColor.withOpacity(0),
                            theme.dividerColor,
                            theme.dividerColor,
                          ],
                          stops: const [0.0, 0.05, 0.2, 0.8, 0.95, 1.0]
                      )
                  ),
                ),

                Transform.translate(
                  offset: const Offset(8, 40 - 24/2),
                  child: Icon(Icons.chevron_left_rounded, color: theme.shadowColor, size: 24,),
                ),
                Transform.translate(
                  offset: Offset(constraints.maxWidth - 24 - 8, 40 - 24/2),
                  child: Icon(Icons.chevron_right_rounded, color: theme.shadowColor, size: 24,),
                ),
              ],
            ),
          )
        ),
      );
  }

}


class GradeEditResult {
  final GradeEntry entry;
  final Subject subject;
  final Semester semester;
  final bool remove;

  GradeEditResult(this.entry, this.subject, this.semester, this.remove);
}
