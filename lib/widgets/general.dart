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
      Expanded(flex: 100, child: Text(subject.name, softWrap: false, overflow: TextOverflow.ellipsis, maxLines: 2, style: theme.textTheme.headlineMedium)),
      // Expanded(flex: 100, child: ,),
    ],));
  }
}
