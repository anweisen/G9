import 'package:flutter/material.dart';

import '../logic/types.dart';
import '../provider/settings.dart';
import '../widgets/skeleton.dart';
import '../widgets/colorpicker.dart';
import '../widgets/subpage.dart';
import 'grade.dart';

class CustomizeSubjectPage extends StatefulWidget {
  const CustomizeSubjectPage({super.key, required this.subject, required this.initialSettings});

  final Subject subject;
  final SubjectSettings? initialSettings;

  @override
  State<CustomizeSubjectPage> createState() => _CustomizeSubjectPageState();
}

class _CustomizeSubjectPageState extends State<CustomizeSubjectPage> {

  Color? _color;
  int _resetKey = 0;

  @override
  void initState() {
    _color = widget.subject.color;
    super.initState();
  }

  Color get currentColor => _color ?? defaultColor;
  Color get defaultColor => Subject.originalColors[widget.subject.id]!;

  bool get isDefaultColor => _color == null || _color == defaultColor;

  SubjectSettings createSettings() {
    return widget.initialSettings?.copyWithColorValue(_color?.toARGB32()) ?? SubjectSettings(colorValue: _color?.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color contrastColor = currentColor.computeLuminance() > 0.78 ? (theme.brightness == Brightness.light ? Colors.black : Colors.black87) : Colors.white;

    return SubpageSkeleton(
        title: Text("Fachdarstellung anpassen", style: theme.textTheme.headlineMedium),
        actions: [
          SaveButtonContainer(btn1: SaveButton(
            onTap: () {
              SubpageController.of(context).closeSubpage(createSettings());
            },
            shown: true,
            index: 0,
            icon: Icons.check_rounded,
            text: "Speichern",
          ), btn2: null, shown: true)
        ],
        children: [
          Container(
            decoration: BoxDecoration(
              color: currentColor.withAlpha(theme.brightness == Brightness.dark ? 150 : 166),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: currentColor,
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

          ColorPicker(initialColor: currentColor, key: ValueKey(_resetKey), onColorChanged: (color) {
            setState(() {
              _color = color;
            });
          },),

          const SizedBox(height: 20,),

          GestureDetector(
            onTap: () {
              setState(() {
                _color = null;
                _resetKey++; // force reset of color picker state -> reset to initial/default color
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.rotate_left_rounded, color: isDefaultColor ? theme.shadowColor : theme.primaryColor, size: 22,),
                  const SizedBox(width: 6,),
                  Text("Zurücksetzen", style: theme.textTheme.bodyMedium?.copyWith(color: isDefaultColor ? theme.shadowColor : theme.primaryColor, fontWeight: FontWeight.w500, fontSize: 16),),
                ],
              ),
            ),
          )
        ]
    );
  }
}

