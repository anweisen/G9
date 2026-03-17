import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key, required this.initialColor, this.onColorChanged});

  final Color initialColor;
  final Function(Color)? onColorChanged;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {

  late Color _color;
  late Color _colorHue;
  late double _relativeX, _relativeY;
  late double _hue = 100; // 0–360

  @override
  void initState() {
    _initializeFromColor(widget.initialColor);
    super.initState();
  }

  void _initializeFromColor(Color color) {
    HSVColor hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _color = color;
    _colorHue = HSVColor.fromAHSV(1, _hue, 1, 1).toColor();
    _relativeX = hsv.saturation;
    _relativeY = 1 - hsv.value;
  }

  void _setHue(double hue) {
    setState(() {
      _hue = hue;
      _colorHue = HSVColor.fromAHSV(1, _hue, 1, 1).toColor();
      _color = HSVColor.fromAHSV(1, _hue, _relativeX, 1 - _relativeY).toColor();
    });
    widget.onColorChanged?.call(_color);
  }

  void _handlePan(Offset localPosition, double maxWidth) {
    double relativeX = localPosition.dx / maxWidth;
    double relativeY = localPosition.dy / 200;

    // Clamp values between 0 and 1
    relativeX = relativeX.clamp(0.0, 1.0);
    relativeY = relativeY.clamp(0.0, 1.0);

    setState(() {
      _relativeX = relativeX;
      _relativeY = relativeY;
      _color = HSVColor.fromAHSV(1, _hue, relativeX, 1 - relativeY).toColor();
      _colorHue = HSVColor.fromAHSV(1, _hue, 1, 1).toColor();
    });
    widget.onColorChanged?.call(_color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.dividerColor,
      ),
      child: LayoutBuilder(
        builder: (context, constraints)  {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.color_lens_outlined, color: theme.shadowColor, size: 14,),
                  const SizedBox(width: 6,),
                  Text("Farbe auswählen", style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10,),
              GestureDetector(
                onVerticalDragUpdate: (details) => _handlePan(details.localPosition, constraints.maxWidth),
                onPanDown: (details) => _handlePan(details.localPosition, constraints.maxWidth),
                onPanUpdate: (details) => _handlePan(details.localPosition, constraints.maxWidth),
                onPanStart: (details) => _handlePan(details.localPosition, constraints.maxWidth),
                child: Stack(
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        minHeight: 200,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(9)),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            _colorHue,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black,
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          )
                        )
                      ),
                    ),

                    Positioned(
                      left: (_relativeX * constraints.maxWidth) - 10,
                      top: (_relativeY * 200) - 10,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          color: _color,
                        ),
                        width: 20,
                        height: 20,
                      )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ColorPickerHueSlider(
                hue: _hue,
                maxWidth: constraints.maxWidth,
                onChanged: (newHue) => _setHue(newHue),
              ),
            ],
          );
        }
      ),
    );
  }

}

class ColorPickerHueSlider extends StatelessWidget {
  const ColorPickerHueSlider({
    super.key,
    required this.hue,
    required this.maxWidth,
    required this.onChanged,
  });

  final double maxWidth;
  final double hue; // 0–360
  final ValueChanged<double> onChanged;

  static List<Color> hueColors = List.generate(13, (i) {
    final hue = (i * 360 / 12).toDouble();
    return HSVColor.fromAHSV(1, hue, 1, 1).toColor();
  });

  void _handlePan(Offset location) {
    double relativeX = location.dx / maxWidth;
    relativeX = relativeX.clamp(0.0, 1.0);
    double newHue = relativeX * 360;
    onChanged(newHue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onPanDown: (details) => _handlePan(details.localPosition),
      onPanUpdate: (details) => _handlePan(details.localPosition),
      onPanStart: (details) => _handlePan(details.localPosition),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(9)),
              gradient: LinearGradient(
                colors: hueColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            width: maxWidth,
            height: 20,
            margin: const EdgeInsets.symmetric(vertical: 5),
          ),
          Positioned(
            left: maxWidth * (hue / 360) - 5,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.primaryColor, width: 2),
                borderRadius: BorderRadius.circular(6),
                color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
              ),
              width: 10,
              height: 30,
            )
          ),
        ],
      ),
    );
  }
}
