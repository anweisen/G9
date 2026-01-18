import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logic/types.dart';

class SubjectPageTitle extends StatelessWidget {
  final Subject subject;

  const SubjectPageTitle({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(flex: 100, child: Row(children: [
      Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: subject.color),
        width: 24,
        height: 24,
      ),
      const SizedBox(width: 12),
      Expanded(flex: 100, child: Text(subject.name, softWrap: false, overflow: TextOverflow.ellipsis, maxLines: 1, style: theme.textTheme.headlineMedium)),
    ],));
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
