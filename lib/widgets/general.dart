import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/types.dart';
import '../pages/customize.dart';
import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import 'subpage.dart';

extension StringExtension on String {
  String truncateTo(int maxChars) {
    if (length <= maxChars) {
      return this;
    }
    return "${substring(0, maxChars)}...";
  }
}

class SubjectPageTitle extends StatelessWidget {
  final Subject subject;

  const SubjectPageTitle({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(flex: 100, child: SubpageTrigger(
      createSubpage: () => CustomizeSubjectPage(subject: subject),
      callback: (result) {
        if (result != null && result is SubjectSettings) {
          Provider.of<SettingsDataProvider>(context, listen: false).setSubjectSettings(subject.id, result);
          Provider.of<AccountDataProvider>(context, listen: false).updateSubjectSettings(subject.id, result);
        }
      },
      child: Row(children: [
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: subject.color),
          width: 22,
          height: 22,
        ),
        const SizedBox(width: 10),
        Expanded(flex: 100, child: Text(subject.name, softWrap: false, overflow: TextOverflow.ellipsis, maxLines: 1, style: theme.textTheme.headlineMedium)),
      ],),
    ));
  }
}

class SubjectSemesterSubtitle extends StatelessWidget {
  const SubjectSemesterSubtitle({super.key, required this.subtitle, required this.choice, required this.subject, required this.semester});

  final String subtitle;
  final Choice choice;
  final Subject subject;
  final Semester semester;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(subtitle, softWrap: false, overflow: TextOverflow.ellipsis, maxLines: 1, style: theme.textTheme.bodyMedium),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(6)),
              child: Text(semester.detailedDisplay, style: theme.textTheme.displayMedium?.copyWith(height: 1.25),)
            ),
            if (choice.lk == subject) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(6)),
              child: Text("Leistungsfach", style: theme.textTheme.displayMedium?.copyWith(height: 1.25),)
            ),
          ],
        )
      ],
    );
  }
}


// hacky fix for ios web blur filter issues
class SafeBackdropFilter extends StatefulWidget {
  final ImageFilter filter;
  final Widget child;
  final Widget? backdrop;
  final Duration repaintDelay;

  const SafeBackdropFilter({
    super.key,
    required this.filter,
    required this.child,
    this.backdrop,
    this.repaintDelay = const Duration(milliseconds: 400), // this > animation duration/delay
  });

  @override
  State<SafeBackdropFilter> createState() => _SafeBackdropFilterState();
}

class _SafeBackdropFilterState extends State<SafeBackdropFilter> {
  bool _enableBlur = false;

  bool get _isIOSWeb => kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();

    if (_isIOSWeb) {
      Future.delayed(widget.repaintDelay, () {
        if (mounted) {
          setState(() => _enableBlur = true);
        }
      });
    } else {
      _enableBlur = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // BACKDROP
        if (_enableBlur) BackdropFilter(
          filter: widget.filter,
          child: widget.backdrop ?? const SizedBox.expand(),
        ),

        // FOREGROUND
        widget.child,
      ],
    );
  }
}

class CustomLineBreakText extends StatelessWidget {
  const CustomLineBreakText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('\n');

    return
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            Text(parts[i], style: style ?? DefaultTextStyle.of(context).style),
            if (i < parts.length - 1)
              const SizedBox(height: 5)
          ],
        ],
      );
  }
}

class DotLoadingIndicator extends StatefulWidget {
  const DotLoadingIndicator({super.key, required this.style, required this.duration});

  final TextStyle style;
  final Duration duration;

  @override
  State<DotLoadingIndicator> createState() => _DotLoadingIndicatorState();
}

class _DotLoadingIndicatorState extends State<DotLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration
    )..repeat(); // Loop the animation infinitely

    // StepTween breaks the animation into 4 stages: "", ".", "..", "..."
    _dotCount = IntTween(begin: 1, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 3 * widget.style.fontSize!, // Max width for "..."
      child: AnimatedBuilder(
        animation: _dotCount,
        builder: (context, child) {
          final dots = "." * _dotCount.value;
          return Text(dots, style: widget.style,);
        },
      ),
    );
  }
}

class AnimatedDrawerTransition extends StatelessWidget {
  const AnimatedDrawerTransition({super.key, required this.expanded, required this.duration, required this.child, this.margin});

  final bool expanded;
  final Duration duration;
  final EdgeInsets? margin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.1, 1.0, curve: Curves.linear),
        );

        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: fadeAnimation, // Uses the delayed animation
            child: child,
          ),
        );
      },
      child: expanded ? (margin != null ? Padding(padding: margin!, child: child,) : child) : const SizedBox.shrink(),
    );
  }
}

