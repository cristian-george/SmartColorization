import 'package:flutter/material.dart';
import 'package:photo_app/utils/shared_preferences.dart';

import '../enums.dart';
import '../widgets/custom_list_widget.dart';
import '../widgets/settings/image_format_widget.dart';
import '../widgets/settings/theme_list_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _onListTileTapped(int index) {
    switch (index) {
      case 0:
        showGeneralDialog(
          context: context,
          pageBuilder: (BuildContext context, Animation<double> animation,
                  Animation<double> secondaryAnimation) =>
              const ImageFormatPopup(title: "Image file formats"),
        ).then((value) {
          setState(() {});
        });
        break;
      case 1:
        showGeneralDialog(
          context: context,
          pageBuilder: (BuildContext context, Animation<double> animation,
                  Animation<double> secondaryAnimation) =>
              const ThemePopup(title: "Themes"),
        ).then((value) {
          setState(() {});
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SettingsList(
              onTap: (selectedItems) {
                if (selectedItems.isNotEmpty) {
                  _onListTileTapped(selectedItems.first['id']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsList extends StatefulWidget {
  const SettingsList({Key? key, this.onTap, this.selectedItems})
      : super(key: key);

  final Set<Map<String, dynamic>>? selectedItems;
  final ValueChanged<Set<Map<String, dynamic>>>? onTap;

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  late List<Map<String, dynamic>> _settings;

  _updateSettingsList() {
    final theme = sharedPreferences.getInt('theme')!;
    final format = sharedPreferences.getInt('format')!;

    _settings = [
      {
        "id": 0,
        "name": 'Image file formats',
        "trailing": ImageFormats.values[format].toString().split('.')[1]
      },
      {
        "id": 1,
        "name": 'Themes',
        "trailing": Themes.values[theme].toString().split('.')[1]
      },
    ];
  }

  @override
  void initState() {
    super.initState();

    _updateSettingsList();
  }

  @override
  void didUpdateWidget(covariant SettingsList oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updateSettingsList();
  }

  @override
  Widget build(BuildContext context) {
    return CustomListWidget(
      items: _settings,
      listItemBuilder: (ListItemType type, final Map<String, dynamic> object) {
        switch (type) {
          case ListItemType.title:
            return Text(object['name']);
          case ListItemType.leading:
            break;
          case ListItemType.subtitle:
            break;
          case ListItemType.trailing:
            return Text(object['trailing']);
        }

        return null;
      },
      checkable: false,
      multiSelection: false,
      onTap: (selectedItems) {
        widget.onTap!(selectedItems);
      },
    );
  }
}
