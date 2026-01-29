import 'dart:math';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/types.dart';
import '../provider/grades.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';
import '../logic/grades.dart';
import '../logic/choice.dart';
import '../provider/settings.dart';

class WeightingPage extends StatelessWidget {
  const WeightingPage({super.key, required this.subject, required this.semester});

  final Subject subject;
  final Semester semester;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<GradesDataProvider>(context);
    final grades = provider.getGrades(subject.id, semester: semester);
    final choice = Provider.of<SettingsDataProvider>(context).choice;
    final weighting = GradeHelper.getWeightingFor(subject, semester, choice!, grades);

    return SubpageSkeleton(
        title: Text("Notengewichtung", style: theme.textTheme.headlineMedium),
        children: [
          Wrap(
            verticalDirection: VerticalDirection.up,
            spacing: 12,
            runSpacing: 6,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: subject.color),
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 8),
                Text(subject.name, softWrap: false, overflow: TextOverflow.ellipsis, maxLines: 1, style: theme.textTheme.bodyMedium),
              ]),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(6)),
                      child: Text(semester.detailedDisplay, style: theme.textTheme.displayMedium?.copyWith(height: 1.25),)
                  ),
                  const SizedBox(width: 8),
                  if (choice.lk == subject) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(6)),
                      child: Text("Leistungsfach", style: theme.textTheme.displayMedium?.copyWith(height: 1.25),)
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 8,),
          WeightingDisplay(grades: grades, weighting: weighting,),

          const SizedBox(height: 8,),
          WeightingInfoDisplay(theme: theme, subject: subject, semester: semester, choice: choice, weighting: weighting),
        ]
    );
  }
}

class WeightingInfoDisplay extends StatelessWidget {
  const WeightingInfoDisplay({
    super.key,
    required this.theme,
    required this.subject,
    required this.semester,
    required this.choice,
    required this.weighting,
  });

  final ThemeData theme;
  final Subject subject;
  final Semester semester;
  final Choice? choice;
  final GradeWeighting weighting;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse("https://www.gesetze-bayern.de/Content/Document/BayGSO-${semester == Semester.abi ? "52" : "29"}#content");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel_rounded, size: 16, color: theme.textTheme.bodySmall?.color,),
                  const SizedBox(width: 6,),
                  Text("§ ${semester == Semester.abi ? "52" : "29"} BayGSO", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),),
                ],
              ),
              const SizedBox(height: 8,),
              CustomLineBreakText(weighting.generateInfoText(), style: theme.textTheme.bodySmall),
            ],
          )
      ),
    );
  }
}

class WeightingDisplay extends StatelessWidget {
  const WeightingDisplay({super.key, required this.grades, required this.weighting});

  final GradesList grades;
  final GradeWeighting weighting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final componentCount = weighting.components.length;
    final componentTreeDepth = weighting.calculateComponentTreeDepth();
    final result = weighting.calculateAverage(grades);

    return LayoutBuilder(builder: (context, constraints) {
      final componentSpacing = constraints.maxWidth / (componentCount * 2); // better spacing to the edge
      return SizedBox(
        height: 200 + (weighting.semesterCountEquivalent > 1 ? 20 : 0) + (componentTreeDepth - 1) * 80,
        child: Stack(
          children: [
            ..._buildSubComponents(componentSpacing, componentCount, 0, componentTreeDepth, 1, constraints.maxWidth, weighting.components, theme),
            CenteredPositioned(
              top: 124 + (80 * (componentTreeDepth - 1)),
              left: constraints.maxWidth * 0.5,
              child: WeightedGradleResultDisplay(average: result, semesterCountEquivalent: weighting.semesterCountEquivalent),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildSubComponents(double componentSpacing, int componentCount, double startLeftOffset, int componentTreeDepth,
      int currentDepth, double maxWidth, List<GradeWeightingComponent> components, ThemeData theme) {
    return [
      for (int i = 0; i < componentCount; i++)
        ...(components[i].hasSubComponents) ? _buildSubComponents(
          componentSpacing / componentCount,
          components[i].subcomponents!.length,
          startLeftOffset + (componentSpacing * 2 / componentCount) * (i * 2),
          componentTreeDepth,
          currentDepth + 1,
          maxWidth / componentCount,
          components[i].subcomponents!,
          theme
        ) : [],

      WeightedGradeLine(left: startLeftOffset + componentSpacing, top: 99 + (80.0 * (componentTreeDepth - currentDepth)), width: componentSpacing * (componentCount * 2 - 2), height: 2),
      for (int i = 0; i < componentCount; i++)
        WeightedGradeLine(left: startLeftOffset + componentSpacing * (i * 2 + 1) - 1, top: 99 - 15 + 2 + (80.0 * (componentTreeDepth - currentDepth)), width: 2, height: 15),
      WeightedGradeLine(left: startLeftOffset + maxWidth * 0.5 - 1, top: 99 + (80.0 * (componentTreeDepth - currentDepth)), width: 2, height: 15),

      if (components.length > 1)
        CenteredPositioned(
            top: 80 + (80.0 * (componentTreeDepth - currentDepth)),
            left: startLeftOffset + maxWidth * 0.5,
            child: Text(GradeWeighting.generateWeightingTextForComponents(components), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14))
        ),

      for (int i = 0; i < componentCount; i++)
        CenteredPositioned(
          top: (componentTreeDepth - currentDepth) * 96,
          left: startLeftOffset + componentSpacing * (i * 2 + 1),
          child: WeightedComponentDisplay(component: components[i], grades: components[i].filter(grades), showGradesList: !components[i].hasSubComponents, maxWidth: maxWidth / componentCount,),
        ),
    ];
  }
}

class WeightedComponentDisplay extends StatelessWidget {
  const WeightedComponentDisplay({super.key, required this.grades, required this.showGradesList, required this.component, required this.maxWidth});

  final double maxWidth;
  final GradeWeightingComponent component;
  final GradesList grades;
  final bool showGradesList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: min(88.0, maxWidth - 6)),
                child: Text(component.title, style: theme.textTheme.bodySmall, maxLines: 2, softWrap: true, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
            ),
          ),
        ),
        const SizedBox(height: 2),
        if (showGradesList) Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("(", style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),

            for (GradeEntry entry in grades) ...[
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 18,
                  height: 16,
                  decoration: BoxDecoration(color: theme.shadowColor, borderRadius: BorderRadius.circular(4)),
                  child: Center(child: Text(entry.grade.toString(), style: theme.textTheme.labelMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4), textAlign: TextAlign.center,)
                  )
              ),
            ],
            if (grades.isEmpty)
              Text(" / ", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10, fontWeight: FontWeight.w600)),

            Text(")", style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
            const SizedBox(width: 6),
            Text(GradeHelper.formatNumber(component.calculateAverage(grades), allowZero: true), style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class WeightedGradleResultDisplay extends StatelessWidget {
  const WeightedGradleResultDisplay({super.key, required this.average, required this.semesterCountEquivalent});

  final double average;
  final int semesterCountEquivalent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 38,
          height: 27,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: theme.primaryColor,
          ),
          child: Text(GradeHelper.formatResult(average), style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ø", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300)),
            const SizedBox(width: 6),
            Text(GradeHelper.formatNumber(average, decimals: 2, allowZero: true), style: theme.textTheme.bodyMedium),
          ],
        ),
        if (semesterCountEquivalent > 1)
          Text("(≈ ${GradeHelper.formatNumber(average / semesterCountEquivalent, decimals: 1, allowZero: true)})", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}

class WeightedGradeLine extends StatelessWidget {
  const WeightedGradeLine({super.key, required this.left, required this.top, required this.width, required this.height});

  final double left, top, width, height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(4)), color: theme.shadowColor,),
        )
    );
  }
}

class CenteredPositioned extends StatelessWidget {
  const CenteredPositioned({super.key, required this.child, this.left, this.top});

  final Widget child;
  final double? left, top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.translate(
        offset: const Offset(-0.5, 0),
        child: FractionalTranslation(
          translation: const Offset(-0.5, 0),
          child: child,
        ),
      ),
    );
  }
}
