import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/types.dart';
import '../provider/account.dart';
import '../provider/settings.dart';
import '../widgets/skeleton.dart';
import '../widgets/subjects.dart';
import '../widgets/subpage.dart';
import 'grade.dart';

class OralExamTypeSelectorPage extends StatefulWidget {
  const OralExamTypeSelectorPage({super.key});

  @override
  State<OralExamTypeSelectorPage> createState() => _OralExamTypeSelectorPageState();
}

class _OralExamTypeSelectorPageState extends State<OralExamTypeSelectorPage> {

  late ChoiceBuilder _choiceBuilder;
  late Map<Subject, ExamTypeChoice> _chosenExamTypes;

  @override
  void initState() {
    var settings = Provider.of<SettingsDataProvider>(context, listen: false);
    var choice = settings.choice!;
    _choiceBuilder = ChoiceBuilder.fromChoice(choice);
    _chosenExamTypes = {};
    if (_choiceBuilder.oral1 != null && _choiceBuilder.oral2 != null) {
      for (Subject subject in choice.abiSubjects) {
        var choices = ExamTypeChoice.getChoicesForSubject(subject, _choiceBuilder);
        if (choices.length == 1) {
          _chosenExamTypes[subject] = choices.first;
        }
        _chosenExamTypes[subject] = choice.isSubjectOral(subject) ? ExamTypeChoice.oral : ExamTypeChoice.written;
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    int writtenCount = _chosenExamTypes.values.where((choice) => choice == ExamTypeChoice.written).length;
    int oralCount = _chosenExamTypes.values.where((choice) => choice == ExamTypeChoice.oral).length;
    int writtenMin2Count = 0;
    for (Subject subject in _chosenExamTypes.keys) {
      if (subject == _choiceBuilder.lk || subject == Subject.mathe || subject == Subject.deutsch) {
        if (_chosenExamTypes[subject] == ExamTypeChoice.written) writtenMin2Count++;
      }
    }
    bool invalid = writtenCount != 3 || oralCount != 2 || writtenMin2Count < 2;

    if (!invalid) {
      int index = 0;
      for (Subject subject in _chosenExamTypes.keys) {
        if (_chosenExamTypes[subject] == ExamTypeChoice.oral) {
          if (index == 0) {
            _choiceBuilder.oral1 = subject;
          } else {
            _choiceBuilder.oral2 = subject;
          }
          index++;
        }
      }
    }

    var choice = _choiceBuilder.build();

    return SubpageSkeleton(
        title: Text("Prüfungsarten festlegen", style: theme.textTheme.headlineMedium),
        actions: [
          SaveButtonContainer(btn1: SaveButton(
            onTap: () {
              if (invalid) return;
              Provider.of<SettingsDataProvider>(context, listen: false).choice = choice;
              Provider.of<AccountDataProvider>(context, listen: false).updateChoice(choice);
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
          const SizedBox(height: 6),
          for (Subject subject in choice.abiSubjects) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 4,
              children: [
                Flexible(child: MediumSubjectWidget(subject: subject)),
                _buildOptionLine(theme, subject),
              ],
            ),
            const SizedBox(height: 10),
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
            child: Icon(invalid ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, size: invalid ? 20 : 18, color: invalid ? theme.disabledColor : theme.primaryColor)
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
                  Text("von 3 schriftlich", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: invalid ? theme.disabledColor : theme.primaryColor),),
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
                  const SizedBox(width: 6),
                  Text("von 2 mündlich", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: invalid ? theme.disabledColor : theme.primaryColor),),
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
              child: Icon(invalid ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, size: invalid ? 20 : 18, color: invalid ? theme.disabledColor : theme.primaryColor)
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
                const SizedBox(width: 6),
                Flexible(child: Text("von mindestens 2 schriftlichen Prüfungen in Deutsch, Mathe, Leistungsfach", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: invalid ? theme.disabledColor : theme.primaryColor), softWrap: true,)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionLine(ThemeData theme, Subject subject) {
    List<ExamTypeChoice> choices = ExamTypeChoice.getChoicesForSubject(subject, _choiceBuilder);
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          const SizedBox(width: 10),
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
