import 'package:flutter/material.dart';

import '../../enums.dart';
import '../../utils/shared_preferences.dart';

class ImageFormatPopup extends StatefulWidget {
  const ImageFormatPopup({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<ImageFormatPopup> createState() => _ImageFormatPopupState();
}

class _ImageFormatPopupState extends State<ImageFormatPopup> {
  late ImageFormats _selectedImageFormat;

  @override
  void initState() {
    super.initState();

    final idx = sharedPreferences.getInt('format')!;
    _selectedImageFormat = ImageFormats.values[idx];
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
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.4,
        child: ImageFormatListWidget(
          onSelectionChanged: (format) {
            setState(() {
              _selectedImageFormat = format;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            //getIt<ThemeModeSelector>().setThemeMode(_selectedTheme);
            sharedPreferences.setInt('format', _selectedImageFormat.index);
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
      alignment: Alignment.center,
    );
  }
}

class ImageFormatListWidget extends StatefulWidget {
  final Function(ImageFormats) onSelectionChanged;

  const ImageFormatListWidget({Key? key, required this.onSelectionChanged})
      : super(key: key);

  @override
  State<ImageFormatListWidget> createState() => _ImageFormatListWidgetState();
}

class _ImageFormatListWidgetState extends State<ImageFormatListWidget> {
  late ImageFormats _selectedImageFormat;

  @override
  void initState() {
    super.initState();

    final idx = sharedPreferences.getInt('format')!;
    _selectedImageFormat = ImageFormats.values[idx];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ImageFormats.values.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            ImageFormats.values[index].toString().split('.')[1],
            style: TextStyle(color: Colors.grey[800] as Color),
          ),
          trailing: _selectedImageFormat == ImageFormats.values[index]
              ? const Icon(
                  Icons.check,
                  color: Colors.blueAccent,
                )
              : null,
          onTap: () {
            setState(() {
              _selectedImageFormat = ImageFormats.values[index];
              widget.onSelectionChanged(_selectedImageFormat);
            });
          },
        );
      },
    );
  }
}
