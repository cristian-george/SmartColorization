import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerPopup extends StatefulWidget {
  const ColorPickerPopup({
    Key? key,
    required this.title,
    required this.onPickedColor,
    required this.initialColor,
  }) : super(key: key);

  final String title;
  final Color initialColor;
  final Function(Color) onPickedColor;

  @override
  State<ColorPickerPopup> createState() => _ColorPickerPopupState();
}

class _ColorPickerPopupState extends State<ColorPickerPopup> {
  late Color _pickedColor;

  @override
  void initState() {
    super.initState();

    _pickedColor = widget.initialColor;
    print('Initial picked color: ${RgbColor.fromColor(_pickedColor)}');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.title,
        style: TextStyle(
          color: Colors.grey[800] as Color,
        ),
      ),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _pickedColor,
          onColorChanged: (Color color) {
            // Convert the RGB color to LAB color
            LabColor labColor = RgbColor.fromColor(color).toLabColor();

            // Now you can access the lightness of the color
            final lightness = labColor.lightness;
            print('Lightness: $lightness');
          },
          colorPickerWidth: 300.0,
          pickerAreaHeightPercent: 0.7,
          enableAlpha: true,
          displayThumbColor: true,
          paletteType: PaletteType.hsv,
          pickerAreaBorderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2.0),
            topRight: Radius.circular(2.0),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onPickedColor(_pickedColor);
            RgbColor rgbColor = RgbColor.fromColor(_pickedColor);
            print('Lightness: ${rgbColor.toLabColor().lightness}');
            print('Picked color: $rgbColor');
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  void _changeColor(Color color) {
    _pickedColor = color;
  }
}
