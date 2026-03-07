import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/choice.dart';
import '../logic/grades.dart';
import '../logic/types.dart';
import '../logic/results.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../provider/grades.dart';

class GradesTendencyPage extends StatefulWidget {
  const GradesTendencyPage({super.key, required this.subject, required this.semester, required this.grades, required this.choice, required this.gradesProvider});

  final Choice choice;
  final Subject subject;
  final Semester semester;
  final GradesList grades;
  final GradesDataProvider gradesProvider;

  @override
  State<GradesTendencyPage> createState() => _GradesTendencyPageState();
}

class _GradesTendencyPageState extends State<GradesTendencyPage> {

  late GradeWeighting weighting;
  late List<GradeWeightingComponent> components;
  GradesList _addedManual = [];
  GradesList _addedTarget = [];
  bool _targetEnabled = false;
  bool _targetFailed = false;
  late int _target;

  get allGrades => [...widget.grades, ..._addedManual, ..._addedTarget];

  @override
  void initState() {
    weighting = GradeHelper.getWeightingFor(widget.subject, widget.semester, widget.choice, widget.grades);
    components = weighting.flattenComponents();

    if (widget.grades.isEmpty) {
      final results = SemesterResult.calculateResultsWithPredictions(widget.choice, widget.gradesProvider);
      _target = SemesterResult.calculatePrediction(widget.subject, results);
    } else {
      _target = GradeHelper.roundResult(weighting.calculateAverage(widget.grades) / widget.semester.semesterCountEquivalent);
    }

    for (var component in components) {
      print("Component: ${component.title}, singleGrade: ${component.singleGrade}");
    }

    super.initState();
  }

  void _setUpdatedWeightingComponents() {
    weighting = GradeHelper.getWeightingFor(widget.subject, widget.semester, widget.choice, allGrades);
    components = weighting.flattenComponents();
  }

  void _addGrade(GradeWeightingComponent component) {
    setState(() {
      var newGradeEntry = GradeEntry(_calculateComponentAverage(component), component.getRepresentativeGradeType(), DateTime.now());
      _addedManual.add(newGradeEntry);
      _setUpdatedWeightingComponents();
      _setRecalculateTarget();
    });
  }

  void _deleteGrade(GradeEntry grade) {
    setState(() {
      _addedManual.remove(grade);
      _setUpdatedWeightingComponents();
      _setRecalculateTarget();
    });
  }

  void _replaceGrade(GradeEntry grade, int newGrade) {
    setState(() {
      final newGradeEntry = GradeEntry(newGrade, grade.type, grade.date);
      final index = _addedManual.indexOf(grade);
      if (index != -1) {
        _addedManual[index] = newGradeEntry;
      } else {
        _addedManual.add(newGradeEntry);
      }
      _setUpdatedWeightingComponents();
      _setRecalculateTarget();
    });
  }

  void _setTarget(int newTarget) {
    setState(() {
      _targetEnabled = true;
      _target = newTarget;
      _setRecalculateTarget();
    });
  }

  void _toggleTargetEnabled() {
    setState(() {
      _targetEnabled = !_targetEnabled;
      _setRecalculateTarget();
    });
  }

  void _setRecalculateTarget() {
    if (_targetEnabled) {
      var added = _recalculateTarget();
      if (added != null) {
        _addedTarget = added;
      }
      _targetFailed = added == null;
    } else {
      _addedTarget = [];
      _targetFailed = false;
    }
  }

  GradesList? _recalculateTarget() {
    return _recalculateTargetRecursively(0, []);
  }

  GradesList? _recalculateTargetRecursively(int componentIndex, GradesList added) {
    const maxN = 10; // max grades to add per component (limit)

    if (componentIndex >= components.length) {
      var average = weighting.calculateAverage([...widget.grades, ..._addedManual, ...added]);
      var result = GradeHelper.roundResult(average) / widget.semester.semesterCountEquivalent;
      if (result >= _target) {
        return added;
      }
      return null;
    }

    var component = components[componentIndex];
    bool isFinal = component.singleGrade && component.filter([...widget.grades, ..._addedManual]).isNotEmpty;
    if (isFinal) {
      return _recalculateTargetRecursively(componentIndex + 1, added);
    } else {
      for (int n = 0; n < maxN && (!component.singleGrade || n < 1); n++) {
        for (int grade = 0; grade <= 15; grade++) {
          var newAdded = [...added];
          for (int x = 0; x <= n; x++) {
            newAdded.add(GradeEntry(grade, component.getRepresentativeGradeType(), DateTime.now()));
          }

          var result = _recalculateTargetRecursively(componentIndex + 1, newAdded);
          if (result != null) {
            return result;
          }
        }
      }
    }

    return null;
  }

  int _calculateComponentAverage(GradeWeightingComponent component) {
    final allGrades = [...widget.grades, ..._addedManual].where((entry) => entry.type != GradeType.result).toList();
    if (allGrades.isEmpty) {
      final results = SemesterResult.calculateResultsWithPredictions(widget.choice, widget.gradesProvider);
      return SemesterResult.calculatePrediction(widget.subject, results);
    }
    final componentGrades = component.filter(allGrades);
    if (componentGrades.isEmpty) {
      return GradeHelper.unweightedAverageOf(allGrades).round();
    }
    return GradeHelper.unweightedAverageOf(componentGrades).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final grades = allGrades;

    final average = weighting.calculateAverage(grades);
    final result = GradeHelper.roundResult(average);
    final equivalentResult = GradeHelper.roundResult(average / widget.semester.semesterCountEquivalent);

    final grouped = _groupGradesByComponent(grades, components);

    return SubpageSkeleton(
        title: Row(
          children: [
            SubjectPageTitle(subject: widget.subject),
          ],
        ),
        children: [
          SubjectSemesterSubtitle(subtitle: "Notencheck", choice: widget.choice, subject: widget.subject, semester: widget.semester),
          const SizedBox(height: 16,),

          Row(
            children: [
              Row(
                children: [
                  Text("Ø", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w300, color: theme.primaryColor)),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 54,
                    child: Text(GradeHelper.formatNumber(average, decimals: 2, allowZero: true), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.primaryColor))
                  ),
                  if (widget.semester.semesterCountEquivalent > 1) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text("≈ ${GradeHelper.formatNumber(result / widget.semester.semesterCountEquivalent)}", style: theme.textTheme.displayMedium?.copyWith(height: 1.25, color: theme.primaryColor))
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 16),
              Container(
                  width: 37,
                  height: 27,
                  decoration: BoxDecoration(
                    color: equivalentResult >= 5 ? theme.primaryColor : theme.splashColor,
                    borderRadius: BorderRadius.circular(6)
                  ),
                  child: Center(
                    child: Text(result.toString(),
                    style: theme.textTheme.labelMedium?.copyWith(color: equivalentResult < 5 ? theme.disabledColor : null))
                  )
              ),
            ],
          ),

          const SizedBox(height: 16,),
          Container(
            height: 2,
            width: double.infinity,
            color: theme.dividerColor,
          ),
          const SizedBox(height: 16,),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Zielnote", style: theme.textTheme.bodySmall),
              const SizedBox(height: 4,),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleTargetEnabled,
                    child: Icon(
                      _targetEnabled ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                      size: 18,
                      color: _targetEnabled ? theme.primaryColor : theme.shadowColor,
                    ),
                  ),
                  const SizedBox(width: 8,),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _setTarget(max(_target - 1, 0)),
                          child: Icon(Icons.remove, size: 20, color: theme.shadowColor)
                        ),
                        const SizedBox(width: 3,),
                        SizedBox(
                          width: 25,
                          child: Text(_target.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: _targetEnabled ? null : theme.shadowColor), textAlign: TextAlign.center),
                        ),
                        const SizedBox(width: 3,),
                        GestureDetector(
                          onTap: () => _setTarget(min(_target + 1, 15)),
                          child: Icon(Icons.add, size: 20, color: theme.shadowColor)
                        ),
                      ],
                    ),
                  )
                ],
              ),
              if (_targetEnabled && _targetFailed) ...[
                const SizedBox(height: 6,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: theme.disabledColor),
                    const SizedBox(width: 10,),
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(top: 3),
                        child: Text("Zielnote ist mit diesen Noten nicht mehr realistisch erreichbar", style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor, height: 1), softWrap: true, maxLines: 3,),
                      )
                    ),
                  ],
                )
              ]
            ],
          ),

          const SizedBox(height: 16,),
          Container(
            height: 2,
            width: double.infinity,
            color: theme.dividerColor,
          ),
          const SizedBox(height: 26,),

          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              for (MapEntry<GradeWeightingComponent, GradesList> entry in grouped.entries)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key.title, style: theme.textTheme.bodySmall, textAlign: TextAlign.left),
                        Text("Ø ${GradeHelper.formatNumber(entry.key.calculateAverage(entry.value), allowZero: true)}", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.left),
                      ],
                    ),
                    const SizedBox(height: 4,),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (GradeEntry grade in entry.value)
                          if (_addedManual.contains(grade)) Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                    width: 20,
                                    child: Text(grade.grade.toString(), style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor), textAlign: TextAlign.center,)
                                    ),
                                  const SizedBox(width: 4,),
                                  GestureDetector(
                                    onTap: () => _deleteGrade(grade),
                                    child: Icon(Icons.delete_rounded, size: 19, color: theme.shadowColor)
                                  ),
                                  ],
                                ),
                                ),
                                const SizedBox(height: 3,),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _replaceGrade(grade, min(grade.grade + 1, 15)),
                                      child: Icon(Icons.add_circle_outline_rounded, size: 20, color: theme.shadowColor)
                                    ),
                                    const SizedBox(width: 8,),
                                    GestureDetector(
                                      onTap: () => _replaceGrade(grade, max(grade.grade - 1, 0)),
                                      child: Icon(Icons.remove_circle_outline_rounded, size: 20, color: theme.shadowColor)
                                    ),
                                  ],
                                )
                              ],
                            )
                          else if (_addedTarget.contains(grade)) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text("${grade.grade}", style: theme.textTheme.bodyMedium),
                          ) else Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text("${grade.grade}", style: theme.textTheme.labelMedium),
                          ),
                        if (!entry.key.singleGrade || entry.value.isEmpty)
                          GestureDetector(
                            onTap: () => _addGrade(entry.key),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.dividerColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              child: Icon(Icons.add_rounded, size: 24, color: theme.shadowColor),
                            ),
                          )
                      ]
                    ),
                  ],
                ),
            ],
          )
        ]
    );
  }

  Map<GradeWeightingComponent, GradesList> _groupGradesByComponent(GradesList grades, List<GradeWeightingComponent> components) {
    Map<GradeWeightingComponent, GradesList> grouped = {};
    for (var component in components) {
      grouped[component] = component.filter(grades);
    }
    return grouped;
  }

}
