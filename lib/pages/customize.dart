import 'package:flutter/material.dart';

import '../widgets/skeleton.dart';
import '../widgets/colorpicker.dart';
import '../logic/types.dart';

class CustomizeSubjectPage extends StatefulWidget {
  const CustomizeSubjectPage({super.key, required this.subject});

  final Subject subject;

  @override
  State<CustomizeSubjectPage> createState() => _CustomizeSubjectPageState();
}

class _CustomizeSubjectPageState extends State<CustomizeSubjectPage> {

  late Subject _subject;

  @override
  void initState() {
    _subject = widget.subject;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color contrastColor = widget.subject.color.computeLuminance() > 0.78 ? (theme.brightness == Brightness.light ? Colors.black : Colors.black87) : Colors.white;

    return SubpageSkeleton(
        title: Text("Fachdarstellung anpassen", style: theme.textTheme.headlineMedium),
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.subject.color.withAlpha(theme.brightness == Brightness.dark ? 150 : 166),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: widget.subject.color,
                  ),
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 10),
                Text(widget.subject.name, style: theme.textTheme.bodyMedium?.copyWith(color: contrastColor), maxLines: 1, overflow: TextOverflow.clip),
              ],
            ),
          ),

          const SizedBox(height: 20,),

          ColorPicker(initialColor: widget.subject.color, onColorChanged: (color) {
            _subject.color = color;
            setState(() {
              _subject = _subject;
            });
          },)
        ]
    );
  }
}

