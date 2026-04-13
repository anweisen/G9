import 'package:flutter/material.dart';

import '../logic/types.dart';

class MediumSubjectWidget extends StatelessWidget {
  const MediumSubjectWidget({super.key, required this.subject, this.faded = false});

  final Subject subject;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: subject.color.withValues(alpha: faded ? 0.6 : null)),
          width: 19,
          height: 19,
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(subject.name, style: theme.textTheme.bodyMedium?.copyWith(color: faded ? theme.shadowColor : null), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,)),
      ],
    );
  }
}
