import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../logic/grades.dart';
import '../logic/results.dart';
import 'general.dart';

class GradesPieChart extends StatefulWidget {
  const GradesPieChart({super.key, required this.grades, required this.results});

  final List<GradeEntry> grades;
  final List<SemesterResult> results;

  @override
  State<GradesPieChart> createState() => _GradesPieChartState();
}

class _GradesPieChartState extends State<GradesPieChart> {
  late PageController _controller;
  bool _expanded = false;

  @override
  void initState() {
    _controller = PageController();
    _controller.addListener(() => _closeExpanded());
    super.initState();
  }

  void _closeExpanded() {
    if (_expanded) {
      setState(() {
        _expanded = false;
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  Map<int, int> _countGrades() {
    Map<int, int> gradeCounts = {};
    for (var entry in widget.grades) {
      gradeCounts[entry.grade] = (gradeCounts[entry.grade] ?? 0) + 1;
    }
    return gradeCounts;
  }

  Map<int, int> _countResults() {
    Map<int, int> resultCounts = {};
    for (var entry in widget.results) {
      resultCounts[entry.effectiveGrade] = (resultCounts[entry.effectiveGrade] ?? 0) + entry.semester.semesterCountEquivalent;
    }
    return resultCounts;
  }

  Map<int, int> _withGroupedAsRemaining(Map<int, int> counts) {
    Map<int, int> collapsed = {};
    int total = counts.values.fold(0, (sum, val) => sum + val);
    int threshold = (total * 0.04).round();
    int remainingCount = 0;
    for (var key in counts.keys) {
      if (counts[key]! < threshold) {
        remainingCount += counts[key]!;
      } else {
        collapsed[key] = counts[key]!;
      }
    }
    if (remainingCount > 0) {
      collapsed[-1] = remainingCount;
    }
    return collapsed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Map<int, int> gradeCounts = _countGrades();
    Map<int, int> resultCounts = _countResults();
    Map<int, int> collapsedGradeCounts = _withGroupedAsRemaining(gradeCounts);
    Map<int, int> collapsedResultCounts = _withGroupedAsRemaining(resultCounts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.donut_large_rounded, size: 15, color: theme.textTheme.bodySmall?.color,),
            const SizedBox(width: 5,),
            Text("Notenverteilung", style: theme.textTheme.bodySmall),
          ],
        ),
        // Text("Notenverteilung", style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        LayoutBuilder(
            builder: (context, constraints) {
              double minSide = min(constraints.maxWidth, constraints.maxHeight);
              double cappedMinSide = min(minSide * 0.6, 160);
              return GestureDetector(
                onTapUp: (details) {
                  if (_controller.hasClients) {
                    final tapPosition = details.localPosition.dx;
                    final pageWidth = constraints.maxWidth;
                    if (tapPosition < pageWidth * 0.25) {
                      _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else if (tapPosition > pageWidth * 0.75) {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      _toggleExpanded();
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.shadowColor.withValues(alpha: 0.1)
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: cappedMinSide + 36,
                        child: Stack(
                          children: [
                            PageView(
                              controller: _controller,
                              children: [
                                _buildPage(theme, cappedMinSide, "einzelne Noten", GradesPieChartPainter(gradeCounts: collapsedGradeCounts, theme: theme)),
                                _buildPage(theme, cappedMinSide, "Einbringungen", GradesPieChartPainter(gradeCounts: collapsedResultCounts, theme: theme)),
                              ],
                            ),

                            IgnorePointer(
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: theme.primaryColor),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.primaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedDrawerTransition(
                        expanded: _expanded,
                        duration: const Duration(milliseconds: 500),
                        margin: const EdgeInsets.only(top: 10),
                        child: _buildExpandedDrawerContent(theme,
                          _controller.hasClients && _controller.page != null && _controller.page! < 0.5 ? gradeCounts : resultCounts,
                          _controller.hasClients && _controller.page != null && _controller.page! < 0.5 ? collapsedGradeCounts : collapsedResultCounts
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (index) => _buildDot(index, theme)),
                      ),
                    ],
                  ),
                ),
              );
            }
        ),
      ],
    );
  }

  Widget _buildPage(ThemeData theme, double cappedSize, String name, CustomPainter painter) {
    return Column(
      children: [
        const SizedBox(height: 4,),
        Center(
          child: SizedBox(
            height: cappedSize,
            width: cappedSize,
            child: CustomPaint(
              size: Size(cappedSize, cappedSize),
              painter: painter,
            ),
          ),
        ),
        const SizedBox(height: 10,),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: theme.shadowColor.withValues(alpha: 0.15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(name, style: theme.textTheme.displayMedium?.copyWith(color: theme.shadowColor, fontWeight: FontWeight.w500, fontSize: 12, height: 0)),
              Icon(Icons.info_outline_rounded, size: 14, color: theme.shadowColor),
            ],
          )
        ),
      ],
    );
  }

  Widget _buildExpandedDrawerContent(ThemeData theme, Map<int, int> fullCounts, Map<int, int> collapsedCounts) {
    // keys: order in chart (descending by value/count), collapsed (-1 for remaining)
    // entries: order in drawer (descending by key/grade), full (including collapsed)
    final keys = (collapsedCounts.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.key - a.key)).map<int>((e) => e.key).toList();
    final entries = (fullCounts.entries.where((entry) => entry.value > 0).toList()..sort((a, b) => b.key - a.key));
    final total = fullCounts.values.fold(0, (sum, val) => sum + val);
    return LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300, // max item width
                mainAxisExtent: 30,      // item height
                crossAxisSpacing: 40,    // horizontal distance between columns
                mainAxisSpacing: 10,     // vertical Abstand zwischen rows
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                var item = entries[index];
                var indexInChart = keys.indexOf(item.key);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: GradesPieChartPainter.lerpEntryColor(theme, indexInChart, keys.length),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12,),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.key == -1 ? "sonstige" : "${item.key} Punkte", style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor)),
                        const SizedBox(height: 2),
                        Text("${item.value}x", style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                      ],
                    ),
                    const Expanded(child: SizedBox(width: 30),),
                    Text("${((item.value / total) * 100).toStringAsFixed(1)}%", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.primaryColor, fontSize: 16)),
                  ],
                );
              },
            ),
          );
        },
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double selected = 0;
        if (_controller.hasClients) {
          selected = (_controller.page ?? 0);
        }
        double distance = clampDouble((selected - index).abs(), 0, 1);
        double progress = 1 - distance;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: 8 + 8 * progress,
          decoration: BoxDecoration(
            color: Color.lerp(theme.shadowColor, theme.primaryColor, progress),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}


class GradesPieChartPainter extends CustomPainter {
  final ThemeData theme;
  final Map<int, int> gradeCounts;

  GradesPieChartPainter({required this.gradeCounts, required this.theme});

  static Color lerpEntryColor(ThemeData theme, int index, int total) {
    if (index == -1) return Colors.transparent;
    double factor = index / total;
    return theme.hintColor.withValues(alpha: 1 - factor * 0.5);
    // return Color.lerp(theme.primaryColor, theme.shadowColor, factor)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const gap = 2.5;
    const cornerRadius = 5.0;

    final totalCount = gradeCounts.values.fold<int>(0, (sum, val) => sum + val);
    if (totalCount == 0) return;
    final keys = (gradeCounts.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value - a.value)).map<int>((e) => e.key).toList();

    double startAngle = -pi / 2;
    int index = 0;
    for (var key in keys) {
      index++;
      final count = gradeCounts[key]!;

      final share = count / totalCount;
      final sweepAngle = share * 2 * pi;

      final backgroundColor = lerpEntryColor(theme, index, keys.length);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = backgroundColor;

      final path = Path();

      // gap between slices -> move center offset (tip of slice) away from true center
      double centerOffset = gap / (2 * sin(sweepAngle / 2));
      double midAngle = startAngle + (sweepAngle / 2);
      Offset sliceCenter = Offset(
        center.dx + centerOffset * cos(midAngle),
        center.dy + centerOffset * sin(midAngle),
      );
      // adjust radius to account for center offset, so the outer edge of the slice still reaches the original radius
      double effectiveRadius = radius - centerOffset;
      // decrease corner radius for small slices (Cx = 2r * pi * x = r * sweepAngle; sweepAngle = 2 * pi * x; x = share)
      double clampedCornerRadius = min(cornerRadius, (effectiveRadius * sweepAngle) / 3);

      // calculate the points where the straight lines meet the rounded corners
      // offset the angle slightly to account for the corner radius
      double angleOffset = clampedCornerRadius / effectiveRadius;

      // point where the first straight line ends and the corner begins
      double x1 = sliceCenter.dx + (effectiveRadius - clampedCornerRadius) * cos(startAngle);
      double y1 = sliceCenter.dy + (effectiveRadius - clampedCornerRadius) * sin(startAngle);

      // point where the main arc starts after the first corner
      double x2 = sliceCenter.dx + effectiveRadius * cos(startAngle + angleOffset);
      double y2 = sliceCenter.dy + effectiveRadius * sin(startAngle + angleOffset);

      // point where the main arc ends before the second corner
      double x3 = sliceCenter.dx + effectiveRadius * cos(startAngle + sweepAngle - angleOffset);
      double y3 = sliceCenter.dy + effectiveRadius * sin(startAngle + sweepAngle - angleOffset);

      // point where the second straight line starts after the corner
      double x4 = sliceCenter.dx + (effectiveRadius - clampedCornerRadius) * cos(startAngle + sweepAngle);
      double y4 = sliceCenter.dy + (effectiveRadius - clampedCornerRadius) * sin(startAngle + sweepAngle);

      path.moveTo(sliceCenter.dx, sliceCenter.dy);
      path.lineTo(x1, y1);

      // first rounded corner
      path.arcToPoint(Offset(x2, y2), radius: Radius.circular(clampedCornerRadius), clockwise: true,);
      // main outer arc of the pie slice
      path.arcTo(Rect.fromCircle(center: sliceCenter, radius: effectiveRadius), startAngle + angleOffset, sweepAngle - (angleOffset * 2), false,);
      // second rounded corner
      path.arcToPoint(Offset(x4, y4), radius: Radius.circular(clampedCornerRadius), clockwise: true,);
      // back to center
      path.close();

      canvas.drawPath(path, paint);

      if (share > 0.036) {
        final double labelRadius = radius * 0.7; // position inside slice (distance from center)
        final double x = center.dx + labelRadius * cos(midAngle);
        final double y = center.dy + labelRadius * sin(midAngle);
        _drawLabel(canvas, key == -1 ? "x" : "$key", "$count", Offset(x, y), share);
      }

      startAngle += sweepAngle;
    }
  }

  void _drawLabel(Canvas canvas, String title, String subtitle, Offset position, double share) {
    double scalar = clampDouble(share / 0.05, 0.5, 1.0);
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: title,
            style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12 * scalar, height: 0),
          ),
          if (share > 0.1) TextSpan(
            text: "\n($subtitle)",
            style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor.withValues(alpha: 0.7), fontSize: 8 * scalar),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      position.dx - (textPainter.width / 2),
      position.dy - (textPainter.height / 2),
    );

    textPainter.paint(canvas, offset);
  }

  double radians(double degrees) => degrees * (pi / 180);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
