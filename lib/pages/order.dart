import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'change.dart';
import 'customize.dart';
import 'grade.dart';
import '../logic/types.dart';
import '../provider/settings.dart';
import '../provider/account.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../widgets/subjects.dart';
import '../widgets/subpage.dart';

class SubjectOrderPage extends StatefulWidget {
  const SubjectOrderPage({super.key, required this.initialSubjectSettings});

  final Map<SubjectId, SubjectSettings>? initialSubjectSettings;

  @override
  State<SubjectOrderPage> createState() => _SubjectOrderPageState();
}

class _SubjectOrderPageState extends State<SubjectOrderPage> {

  final Map<Subject, int> _subjectOrder = {};
  final Map<Subject, Color> _subjectColors = {};

  @override
  void initState() {
    super.initState();

    Map<SubjectId, SubjectSettings> subjectSettings = widget.initialSubjectSettings ?? {};
    for (MapEntry<SubjectId, SubjectSettings> entry in subjectSettings.entries) {
      Subject? subject = Subject.byId[entry.key];
      if (subject == null) continue;

      if (entry.value.order != null) {
        _subjectOrder[subject] = entry.value.order!;
      }
      if (entry.value.colorValue != null) {
        _subjectColors[subject] = entry.value.color!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsDataProvider>(context);
    final account = Provider.of<AccountDataProvider>(context);
    final subjects = settings.getOrderedSubjects(null, _subjectOrder);

    return SubpageSkeleton(
      title: const PageTitle(title: "Fächerreihenfolge & -darstellung"),
      actions: [
        SaveButtonContainer(btn1: SaveButton(
          onTap: () {
            Map<SubjectId, SubjectSettings> newSubjectSettings = {};
            for (Subject subject in subjects) {
              newSubjectSettings[subject.id] = (widget.initialSubjectSettings?[subject.id] ?? SubjectSettings())
                  .copyWithColorValue(_subjectColors[subject]?.toARGB32())
                  .copyWithOrder(_subjectOrder[subject]);
            }
            settings.setSubjectsSettings(newSubjectSettings);
            account.updateSubjectsSettings(newSubjectSettings);
            SubpageController.of(context).closeSubpage();
          },
          shown: true,
          index: 0,
          icon: Icons.check_rounded,
          text: "Speichern",
        ), btn2: null, shown: true)
      ],
      children: [
        Text("Reihenfolge der Fächer", style: theme.textTheme.bodySmall),
        const SizedBox(height: 4,),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          proxyDecorator: (Widget child, int index, Animation<double> animation) => Material(
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Container(
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: animation.value * 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3 * animation.value, sigmaY: 3 * animation.value),
                    child: Transform.scale(
                      scale: 1 - animation.value * 0.05,
                      child: child,
                    ),
                  ),
                ),
              )
            ),
          ),
          itemExtent: 36,
          itemBuilder: (context, index) {
            Subject subject = subjects[index];
            return ReorderableDragStartListener(
              index: index,
              key: ValueKey(subject.id),
              child: ListTile(
                minTileHeight: 36,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                title: MediumSubjectWidget(subject: subject, overrideColor: _subjectColors[subject],),
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              List<Subject> newOrder = List.from(subjects);
              Subject movedSubject = newOrder.removeAt(oldIndex);
              newOrder.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, movedSubject);

              if (_listsEqual(newOrder, settings.choice!.subjects)) {
                _subjectOrder.clear();
                return;
              }

              for (int i = 0; i < newOrder.length; i++) {
                _subjectOrder[newOrder[i]] = i;
              }
            });
          },
        ),
        const SizedBox(height: 16,),
        ActionButton(
          text: "Zurücksetzen",
          icon: Icons.rotate_left_rounded,
          textColor: _subjectOrder.isEmpty ? theme.shadowColor : theme.primaryColor,
          backgroundColor: null,
          borderColor: theme.dividerColor,
          onTap: () => setState(() => _subjectOrder.clear()),
        ),

        const SizedBox(height: 30,),

        Text("Darstellung der Fächer", style: theme.textTheme.bodySmall),
        const SizedBox(height: 6,),
        if (_subjectColors.isEmpty) ...[
          Text("Keine individuellen Darstellungen", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1)),
        ],
        Column(
          spacing: 8,
          children: [
            for (Subject subject in _subjectColors.keys)
              SubpageTrigger(
                createSubpage: () => CustomizeSubjectPage(subject: subject, initialSettings: settings.subjectSettings?[subject.id],),
                callback: (result) {
                  if (result != null && result is SubjectSettings) {
                    if (result.colorValue == null) {
                      _subjectColors.remove(subject);
                    } else {
                      _subjectColors[subject] = result.color!;
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor, width: 2)
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          SmallSubjectWidget(subject: subject, overrideColor: _subjectColors[subject], old: false, choice: null,),
                          Icon(Icons.edit_rounded, size: 17, color: theme.shadowColor),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _subjectColors.remove(subject)),
                        child: Icon(Icons.delete_forever_rounded, size: 20, color: theme.disabledColor)
                      ),
                    ],
                  ),
                )
              ),
          ],
        ),
        const SizedBox(height: 8,),
        ActionButton(
          text: "Fachdarstellung ändern",
          icon: Icons.add_circle_outline_rounded,
          textColor: theme.primaryColor,
          backgroundColor: null,
          borderColor: theme.dividerColor,
          onTap: null,
          createSubpage: () => const SubjectSelectionPage(semester: null),
          callback: (subject) {
            if (subject is Subject) {
              SubpageController.of(context).openSubpage(
                CustomizeSubjectPage(
                  subject: subject,
                  initialSettings: settings.subjectSettings?[subject.id],
                ), callback: (result) {
                  if (result != null && result is SubjectSettings) {
                    if (result.colorValue != null) {
                      setState(() => _subjectColors[subject] = result.color!);
                    }
                  }
                }
              );
            }
          },
        ),

        const SizedBox(height: 80,),

      ],
    );
  }

  bool _listsEqual(List<Subject> a, List<Subject> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

