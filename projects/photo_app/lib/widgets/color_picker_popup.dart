import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerPopup extends StatefulWidget {
  const ColorPickerPopup({
    Key? key,
    required this.title,
    required this.onPickedColor,
  }) : super(key: key);

  final String title;
  final Function(Color) onPickedColor;

  @override
  State<ColorPickerPopup> createState() => _ColorPickerPopupState();
}

class _ColorPickerPopupState extends State<ColorPickerPopup> {
  Color _pickedColor = Colors.white;

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
          onColorChanged: _changeColor,
          colorPickerWidth: 300.0,
          pickerAreaHeightPercent: 0.7,
          labelTypes: const [],
          enableAlpha: false,
          displayThumbColor: true,
          paletteType: PaletteType.hueWheel,
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
