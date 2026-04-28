import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/kmapi.dart';
import '../logic/choice.dart';
import '../logic/types.dart';
import '../provider/account.dart';
import '../provider/kmapi.dart';
import '../provider/settings.dart';
import '../util/dates.dart';
import '../widgets/datepicker.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../widgets/subjects.dart';
import '../widgets/subpage.dart';
import 'change.dart';
import 'grade.dart';

class OralExamTypeSelectorPage extends StatefulWidget {
  const OralExamTypeSelectorPage({super.key, required this.choice, required this.initialSubjectSettings});

  final Choice choice;
  final Map<SubjectId, SubjectSettings>? initialSubjectSettings;

  @override
  State<OralExamTypeSelectorPage> createState() => _OralExamTypeSelectorPageState();
}

class _OralExamTypeSelectorPageState extends State<OralExamTypeSelectorPage> {

  final Map<Subject, ExamTypeChoice> _chosenExamTypes = {};
  final Map<Subject, DateTime> oralExamDates = {};

  @override
  void initState() {
    super.initState();

    if (widget.choice.hasSelectedExamTypes) {
      for (Subject subject in widget.choice.abiSubjects) {
        var choices = ExamTypeChoice.getChoicesForSubject(subject, widget.choice);
        if (choices.length == 1) {
          _chosenExamTypes[subject] = choices.first;
        }
        _chosenExamTypes[subject] = widget.choice.isSubjectOral(subject) ? ExamTypeChoice.oral : ExamTypeChoice.written;
      }
      if (widget.initialSubjectSettings != null) {
        for (Subject subject in widget.choice.abiSubjects) {
          if (!_chosenExamTypes.containsKey(subject) || _chosenExamTypes[subject] != ExamTypeChoice.oral) continue;
          SubjectSettings? settings = widget.initialSubjectSettings?[subject.id];
          if (settings != null && settings.oralExamDate != null) {
            oralExamDates[subject] = settings.oralExamDate!;
          }
        }
      }
    }
  }

  void _setOralExamDate(Subject subject, DateTime date) {
    print("setting oral exam date for $subject: $date");
    setState(() {
      oralExamDates[subject] = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    int writtenCount = _chosenExamTypes.values.where((choice) => choice == ExamTypeChoice.written).length;
    int oralCount = _chosenExamTypes.values.where((choice) => choice == ExamTypeChoice.oral).length;
    int writtenMin2Count = 0;
    for (Subject subject in _chosenExamTypes.keys) {
      if (subject == widget.choice.lk || subject == Subject.mathe || subject == Subject.deutsch) {
        if (_chosenExamTypes[subject] == ExamTypeChoice.written) writtenMin2Count++;
      }
    }
    bool invalid = writtenCount != 3 || oralCount != 2 || writtenMin2Count < 2;

    return SubpageSkeleton(
        title: const PageTitle(title: "Prüfungsarten festlegen"),
        actions: [
          SaveButtonContainer(btn1: SaveButton(
            onTap: () {
              if (invalid) return;
              int index = 0;
              ChoiceBuilder builder = ChoiceBuilder.fromChoice(widget.choice);
              Map<SubjectId, SubjectSettings> updatedSettings = {};
              for (Subject subject in _chosenExamTypes.keys) {
                if (_chosenExamTypes[subject] == ExamTypeChoice.oral) {
                  if (oralExamDates[subject] != null) {
                    updatedSettings[subject.id] = widget.initialSubjectSettings?[subject.id]?.copyWithOralExamDate(oralExamDates[subject]) ?? SubjectSettings(oralExamDate: oralExamDates[subject]);
                  }

                  if (index == 0) {
                    builder.oral1 = subject;
                  } else {
                    builder.oral2 = subject;
                  }
                  index++;
                }
              }
              var choice = builder.build();

              var settings = Provider.of<SettingsDataProvider>(context, listen: false);
              var account = Provider.of<AccountDataProvider>(context, listen: false);

              settings.choice = choice;
              account.updateChoice(choice);

              for (SubjectId subjectId in updatedSettings.keys) {
                settings.setSubjectSettings(subjectId, updatedSettings[subjectId]!);
                account.updateSubjectSettings(subjectId, updatedSettings[subjectId]!);
              }

              SubpageController.of(context).closeSubpage();
            },
            shown: !invalid,
            index: 0,
            icon: Icons.check_rounded,
            text: "Speichern",
          ), btn2: null, shown: true)
        ],
        children: [

          Text("Gewählte Abiturprüfungsfächer", style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (Subject subject in widget.choice.abiSubjects) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 6,
              children: [
                MediumSubjectWidget(subject: subject),
                _buildOptionLine(theme, subject),
              ],
            ),
            AnimatedDrawerTransition(
              expanded: !invalid && _chosenExamTypes[subject] == ExamTypeChoice.oral,
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.only(bottom: 8),
              child: SubpageTrigger(
                createSubpage: () => SelectOralDatePage(subject: subject, initialDate: oralExamDates[subject],),
                callback: (result) {
                  if (result is DateTime) _setOralExamDate(subject, result);
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor, width: 2),
                    // color: theme.dividerColor,
                  ),
                  child: oralExamDates[subject] == null ? Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20, color: theme.shadowColor),
                      const SizedBox(width: 8),
                      Flexible(child: Text("Kolloquiumstermin eintragen", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.shadowColor), softWrap: true,)),
                    ]
                  ) : Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 20, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Flexible(child: Text(DateHelper.formatDate(oralExamDates[subject]!, useFullYear: true), style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.primaryColor), softWrap: true,)),
                    ]),
                ),
              ),
            ),
            const SizedBox(height: 11),
          ],

          const SizedBox(height: 20),
          _buildCheckCountInfoLine(theme, writtenCount, oralCount),
          const SizedBox(height: 10),
          _buildCheckMinWrittenInfoLine(theme, writtenMin2Count),

          const SizedBox(height: 72),

      ]
    );
  }

  Widget _buildCheckCountInfoLine(ThemeData theme, int writtenCount, int oralCount) {
    bool invalid = writtenCount != 3 || oralCount != 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: invalid ? theme.splashColor : theme.dividerColor,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Icon(invalid ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, size: invalid ? 22 : 20, color: invalid ? theme.disabledColor : theme.primaryColor)
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: invalid ? theme.splashColor : theme.shadowColor.withValues(alpha: 0.25),
                    ),
                    child: Center(child: Text("$writtenCount", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.primaryColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center,))
                  ),
                  const SizedBox(width: 6),
                  Text("von 3 schriftlich", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: invalid ? theme.disabledColor : theme.shadowColor),),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: invalid ? theme.splashColor : theme.shadowColor.withValues(alpha: 0.25),
                    ),
                    child: Center(child: Text("$oralCount", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.primaryColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center,))
                  ),
                  const SizedBox(width: 8),
                  Text("von 2 mündlich", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: invalid ? theme.disabledColor : theme.shadowColor),),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckMinWrittenInfoLine(ThemeData theme, int writtenMin2Count) {
    bool invalid = writtenMin2Count < 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: invalid ? theme.splashColor : theme.dividerColor,
      ),
      child: Row(
        children: [
          SizedBox(
              width: 24,
              height: 24,
              child: Icon(invalid ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, size: invalid ? 22 : 20, color: invalid ? theme.disabledColor : theme.primaryColor)
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: invalid ? theme.splashColor : theme.shadowColor.withValues(alpha: 0.25),
                    ),
                    child: Center(child: Text("$writtenMin2Count", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.primaryColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center,))
                ),
                const SizedBox(width: 8),
                Flexible(child: Text("von mindestens 2 schriftlichen Prüfungen in Deutsch, Mathe, Leistungsfach", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: invalid ? theme.disabledColor : theme.shadowColor), softWrap: true,)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionLine(ThemeData theme, Subject subject) {
    List<ExamTypeChoice> choices = ExamTypeChoice.getChoicesForSubject(subject, widget.choice);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        for (ExamTypeChoice choice in choices) ...[
          GestureDetector(
            onTap: () => (_chosenExamTypes[subject] == choice && choices.length > 1)
                ? setState(() => _chosenExamTypes.remove(subject))
                : setState(() => _chosenExamTypes[subject] = choice),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor, width: 2),
                color: _chosenExamTypes[subject] == choice ? theme.primaryColor : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(_getIconForExamTypeChoice(choice, choices), size: 16, color: _chosenExamTypes[subject] == choice ? theme.scaffoldBackgroundColor : theme.shadowColor),
                  Text(choice.name, style: theme.textTheme.displayMedium?.copyWith(height: 0, fontWeight: FontWeight.w600, color: _chosenExamTypes[subject] == choice ? theme.scaffoldBackgroundColor : null),),
                ],
              ),
            ),
          ),
        ]
      ],
    );
  }

  IconData _getIconForExamTypeChoice(ExamTypeChoice choice, List<ExamTypeChoice> choices) {
    if (choices.length == 1) return Icons.lock_outline_rounded;
    switch (choice) {
      case ExamTypeChoice.written:
        return Icons.edit_rounded;
      case ExamTypeChoice.oral:
        return Icons.message_rounded;
    }
  }
}

class SelectOralDatePage extends StatefulWidget {
  const SelectOralDatePage({super.key, this.initialDate, required this.subject});

  final DateTime? initialDate;
  final Subject subject;

  @override
  State<SelectOralDatePage> createState() => _SelectOralDatePageState();
}

class _SelectOralDatePageState extends State<SelectOralDatePage> {

  DateTime? _selectedDate;

  @override
  void initState() {
    _selectedDate = widget.initialDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kmapi = Provider.of<KmApiProvider>(context);

    return SubpageSkeleton(
        title: const PageTitle(title: "Kolloquiumstermin eintragen"),
        actions: [
          SaveButtonContainer(btn1: SaveButton(
            onTap: () {
              SubpageController.of(context).closeSubpage(_selectedDate);
            },
            shown: _selectedDate != null,
            index: 0,
            icon: Icons.check_rounded,
            text: "Speichern",
          ), btn2: null, shown: true)
        ],
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor, width: 2),
                ),
                child: SmallSubjectWidget(subject: widget.subject, old: false, choice: null,)
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!kmapi.hasError && kmapi.abiDates != null) for (OralAbiExamWeek oralDate in kmapi.abiDates!.oralExamWeeks) ...[
            Text("${oralDate.formattedWeekName} (${DateHelper.formatWeek(oralDate.startDate, oralDate.endDate)})", style: theme.textTheme.displayMedium),
            const SizedBox(height: 6),
            WeekDatePicker(
              selected: _selectedDate,
              start: oralDate.startDate,
              end: oralDate.endDate,
              onDateSelected: (DateTime date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 20),
          ] else DatePicker(
            date: _selectedDate,
            onDateChanged: (DateTime date) => setState(() => _selectedDate = date),
          ),
        ]
    );
  }
}


class WeekDatePicker extends StatelessWidget {
  const WeekDatePicker({super.key, this.selected, required this.start, required this.end, required this.onDateSelected});

  final DateTime? selected;
  final DateTime start, end;
  final Function(DateTime date) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 26,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (DateTime date in _getDaysBetween())
          GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: date == selected ? theme.primaryColor : theme.dividerColor,
              ),
              child: Column(
                children: [
                  Text(DateHelper.shortNameOfWeekday(date.weekday), style: theme.textTheme.bodySmall),
                  Text("${date.day}", style: theme.textTheme.bodyMedium?.copyWith(color: selected != null && date.isAtSameMomentAs(selected!) ? theme.scaffoldBackgroundColor : null),),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<DateTime> _getDaysBetween() {
    List<DateTime> days = [];
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }
}

