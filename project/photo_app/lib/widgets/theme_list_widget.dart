import 'package:flutter/material.dart';
import '../utils/shared_preferences.dart';

class ThemePopup extends StatefulWidget {
  const ThemePopup({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<ThemePopup> createState() => _ThemePopupState();
}

class _ThemePopupState extends State<ThemePopup> {
  late Themes _selectedTheme;

  @override
  void initState() {
    super.initState();

    final idx = sharedPreferences.getInt('theme')!;
    _selectedTheme = Themes.values[idx];
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
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.width * 0.5,
        child: ThemeListWidget(
          onSelectionChanged: (theme) {
            setState(() {
              _selectedTheme = theme;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            //getIt<ThemeModeSelector>().setThemeMode(_selectedTheme);
            sharedPreferences.setInt('theme', _selectedTheme.index);
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
      alignment: Alignment.center,
    );
  }
}

class ThemeListWidget extends StatefulWidget {
  final Function(Themes) onSelectionChanged;

  const ThemeListWidget({Key? key, required this.onSelectionChanged})
      : super(key: key);

  @override
  State<ThemeListWidget> createState() => _ThemeListWidgetState();
}

class _ThemeListWidgetState extends State<ThemeListWidget> {
  late Themes _selectedTheme;

  @override
  void initState() {
    super.initState();

    final idx = sharedPreferences.getInt('theme')!;
    _selectedTheme = Themes.values[idx];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: Themes.values.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            Themes.values[index].toString().split('.')[1],
            style: TextStyle(color: Colors.grey[800] as Color),
          ),
          trailing: _selectedTheme == Themes.values[index]
              ? const Icon(
                  Icons.check,
                  color: Colors.blueAccent,
                )
              : null,
          onTap: () {
            setState(() {
              _selectedTheme = Themes.values[index];
              widget.onSelectionChanged(_selectedTheme);
            });
          },
        );
      },
    );
  }
}
