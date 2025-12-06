import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
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

  @override
  void initState() {
    super.initState();

    _subject = widget.subject;
    _semester = widget.semester;
    _grade = widget.entry?.grade;
    _type = widget.entry?.type;
    _date = widget.entry?.date ?? DateTime.now();
  }

  GradeEntry get entry => GradeEntry(_grade!, _type!, _date!);

  bool get isValid => _grade != null && _type != null && _date != null && _subject != null;

  bool get isFromExisting => widget.entry != null && widget.subject != null;

  void setGrade(int grade) {
    setState(() {
      _grade = grade;
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
    const double leftOffset = PageSkeleton.leftOffset;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: leftOffset),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text("Note ${isFromExisting ? "ändern" : "hinzufügen"}", style: theme.textTheme.headlineMedium),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 4 * (26 + 10), // height + spacing*2
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: leftOffset),
                itemCount: 4,
                itemBuilder: (context, indexI) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int indexJ = 4 * indexI; indexJ < 4 * indexI + 4; indexJ++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: GestureDetector(
                          onTap: () => setGrade(15 - indexJ),
                          child: _buildGradeButton(indexJ, theme, _grade),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: leftOffset),
              child: Column(
                children: [

                  if (_subject == null)
                    const GradeOptionPlaceholder(text: "Wähle ein Fach")
                  else
                    GradeOptionPlaceholder(
                        text: _subject!.name,
                        icon: Container(
                          height: 22,
                          width: 22,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _subject!.color),)
                    ),
                  // on subject/semester change: reset GradeType if need
                  const SizedBox(height: 20),
                  if (_subject == null)
                    const GradeOptionPlaceholder(text: "Wähle ein Semester")
                  else
                    GradeOptionPlaceholder(
                        text: _semester!.detailedDisplay,
                        icon: Icon(Icons.account_tree_rounded, color: theme.primaryColor, size: 24)),
                  const SizedBox(height: 20),
                  GestureDetector(
                      onTap: () => SubpageController.of(context).openSubpage(GradeTypSelectionPage(semester: _semester, subject: _subject, originalType: _type), callback: (type) => {
                        if (type is GradeType) {
                          setType(type)
                        }
                      }),
                      child: (_type == null)
                          ? const GradeOptionPlaceholder(text: "Wähle eine Prüfungsart")
                          : GradeOptionPlaceholder(
                              text: _type!.name,
                              icon: Icon(Icons.label_rounded, color: theme.primaryColor, size: 24))),
                  const SizedBox(height: 20),
                  if (_date == null)
                    const GradeOptionPlaceholder(text: "Wähle ein Datum")
                  else
                    GradeOptionPlaceholder(
                        text: GradeHelper.formatDate(_date!),
                        icon: Icon(Icons.calendar_month_rounded, color: theme.primaryColor, size: 24)),
                ],
              ),
            ),
          ]),

          SaveButtonContainer(
              btn1: SaveButton(
                onTap: () {
                  if (isValid) {
                    SubpageController.of(context).closeSubpage(GradeEditResult(entry, _subject!, false));
                  }
                },
                leftOffset: leftOffset,
                shown: isValid,
                index: 0,
                icon: Icons.chevron_right_rounded,
                text: "Speichern",
              ),
              btn2: isFromExisting ? SaveButton(
                onTap: () {
                  if (isValid) {
                    SubpageController.of(context).closeSubpage(GradeEditResult(entry, _subject!, true));
                  }
                },
                leftOffset: leftOffset,
                shown: true,
                index: 1,
                icon: Icons.delete_forever,
                text: "Löschen",
              ) : null, leftOffset: leftOffset, shown: true,)
        ],
      ),
    );
  }

  Widget _buildGradeButton(int index, ThemeData theme, int? selectedGrade) {
    final int grade = 15 - index;
    return Container(
      width: 56,
      height: 26,
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
        const SizedBox(width: 16),
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
    final List<GradeType> types = (subject != null && semester != null) ? GradeType.types(choice, subject!, semester!) : List.empty();

    return SubpageSkeleton(
        title: Row(
          children: [
            Text("Prüfungsart wählen", style: theme.textTheme.headlineMedium),
          ],
        ),
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
              itemCount: types.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: GestureDetector(
                  onTap:  () => {
                    if (types[index].stillPossible(existingTypes)) {
                      SubpageController.of(context).closeSubpage(types[index])
                    }
                  },
                  child: Padding(
                    padding: (index > 0 && types[index - 1].area != types[index].area)
                        ? const EdgeInsets.only(top: 10)
                        : const EdgeInsets.all(0),
                    child: GradeOptionPlaceholderIcon(
                        textColor: types[index].stillPossible(existingTypes) ? null : theme.textTheme.bodySmall?.color,
                        text: types[index].name,
                        icon: getIcon(types[index])),
                  ),
                ),
              ),
            ),
          ),
    ]);
  }

  IconData getIcon(GradeType type) {
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

class SaveButtonContainer extends StatelessWidget {
  const SaveButtonContainer({super.key, required this.btn1, required this.btn2, required this.leftOffset, required this.shown});

  final SaveButton? btn1, btn2;
  final double leftOffset;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: leftOffset / 1.25,
      left: leftOffset,
      right: leftOffset,
      child: Row(
        children: [
          ..._buildContent(),
        ],
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
    required this.leftOffset,
    required this.shown,
    required this.onTap,
    required this.index, required this.icon, required this.text});

  final int index;
  final double leftOffset;
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(text, style: theme.textTheme.labelMedium),
                  Icon(icon, color: theme.textTheme.labelMedium?.color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradeEditResult {
  final GradeEntry entry;
  final Subject subject;
  final bool remove;

  GradeEditResult(this.entry, this.subject, this.remove);
}
