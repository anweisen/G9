import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../logic/grades.dart';
import '../provider/grades.dart';

class SubjectGradesChart extends StatelessWidget {
  const SubjectGradesChart({super.key, required this.grades, required this.gradesSemesters});

  final List<GradeEntry> grades;
  final List<Semester> gradesSemesters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: min(280, size.height * 0.5) + 50,
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            size: Size(constraints.maxWidth, min(280, size.height * 0.5)),
            painter: GradesChartPainter(grades, gradesSemesters, theme),
          ),
        );
      },
    );
  }
}

class GradesChartPainter extends CustomPainter {
  final List<GradeEntry> grades;
  final List<Semester> semesters;
  final ThemeData theme;

  GradesChartPainter(this.grades, this.semesters, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    const double offsetY = 36;
    const double offsetX = 10;
    final double height = size.height - offsetY * 2 - 40;
    final double width = size.width - offsetX * 2;
    const double labelX = offsetX + 4; // X position of centered label text
    const double labelWidth = 16; // width allocated for labels
    const double dotSize = 4.0;

    final pathPaint = Paint()
      ..color = theme.shadowColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.fill;
    final dividerPaint = Paint()
      ..color = theme.shadowColor.withOpacity(.25)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const minY = 0;
    const maxY = 15;

    Offset mapPoint(GradeEntry entry, int index) {
      final dx = ((index + 0.5) / grades.length) * (width - labelWidth) + offsetX + labelWidth;
      final dy = height + offsetY - (entry.grade - minY) / (maxY - minY) * height;
      return Offset(dx, dy);
    }

    List<Offset> points = grades.asMap().entries.map((entry) => mapPoint(entry.value, entry.key)).toList();

    // draw semester labels + dividers
    late Offset semesterStartPoint;
    for (int i = 0; i < grades.length; i++) {
      if (i == 0 || semesters[i] != semesters[i - 1]) {
        semesterStartPoint = points[i];
      }
      if (i == grades.length - 1 || semesters[i] != semesters[i + 1]) {
        final semesterEndPoint = points[i];
        final textPainter = TextPainter(
          text: TextSpan(
            text: semesters[i].display,
            style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.shadowColor.withOpacity(.5)),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final midX = (semesterStartPoint.dx + semesterEndPoint.dx) / 2;
        textPainter.paint(canvas, Offset(midX - textPainter.width / 2, offsetY / 2 - textPainter.height / 2),);
      }

      if (i < grades.length - 1 && semesters[i] != semesters[i + 1]) {
        semesterStartPoint = points[i];
        final dividerX = (points[i].dx + points[i + 1].dx) / 2;
        drawDashedLine(
            canvas: canvas,
            p1: Offset(dividerX, offsetY),
            p2: Offset(dividerX, height + offsetY),
            pattern: [10, 8],
            paint: dividerPaint
        );
      }
    }

    final path = createCatmullRomPath(points, 0.66);
    canvas.drawPath(path, pathPaint);

    // grade dots + date labels (x-axis)
    for (int i = 0; i < grades.length; i++) {
      canvas.drawCircle(points[i], dotSize, fillPaint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: GradeHelper.formatDate(grades[i].date, includeYear: false, shortMonth: true),
          style: theme.textTheme.bodySmall,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(points[i].dx, height + offsetY*1.75 + (textPainter.width) * cos(-67.5 * pi / 180),); // move origin to centered text position
      canvas.rotate(-67.5 * pi / 180);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 0),); // paint centered
      canvas.restore();
    }

    // grade labels (y-axis)
    for (int i = minY; i <= maxY; i++) {
      final y = height + offsetY - (i - minY) / (maxY - minY) * height;
      final textPainter = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center, // aligns text inside its width
      );
      textPainter.layout(minWidth: labelWidth,);
      // center text horizontally at labelX, vertically at y
      textPainter.paint(canvas, Offset(labelX + (labelWidth - textPainter.width) / 2, y - textPainter.height / 2 + dotSize / 2),);
    }
  }

  Path createCatmullRomPath(List<Offset> points, double tension) {
    final path = Path();
    if (points.length < 2) return path;

    // convert tension to Catmull–Rom alpha
    final t = tension / 6;

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) * t,
        p1.dy + (p2.dy - p0.dy) * t,
      );

      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) * t,
        p2.dy - (p3.dy - p1.dy) * t,
      );

      path.cubicTo(
        cp1.dx, cp1.dy,
        cp2.dx, cp2.dy,
        p2.dx, p2.dy,
      );
    }

    return path;
  }

  void drawDashedLine({
    required Canvas canvas,
    required Offset p1,
    required Offset p2,
    required Iterable<double> pattern,
    required Paint paint,
  }) {
    assert(pattern.length.isEven);
    final distance = (p2 - p1).distance;
    final normalizedPattern = pattern.map((width) => width / distance).toList();
    final points = <Offset>[];
    double t = 0;
    int i = 0;
    while (t < 1) {
      points.add(Offset.lerp(p1, p2, t)!);
      t += normalizedPattern[i++];  // dashWidth
      points.add(Offset.lerp(p1, p2, t.clamp(0, 1))!);
      t += normalizedPattern[i++];  // dashSpace
      i %= normalizedPattern.length;
    }
    canvas.drawPoints(PointMode.lines, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
