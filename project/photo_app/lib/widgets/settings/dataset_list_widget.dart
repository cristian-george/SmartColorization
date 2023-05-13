import 'package:flutter/material.dart';

import '../../enums.dart';
import '../../utils/shared_preferences.dart';

class DatasetPopup extends StatefulWidget {
  const DatasetPopup({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<DatasetPopup> createState() => _DatasetPopupState();
}

class _DatasetPopupState extends State<DatasetPopup> {
  late Datasets _selectedDataset;

  @override
  void initState() {
    super.initState();

    final idx = sharedPreferences.getInt('dataset')!;
    _selectedDataset = Datasets.values[idx];
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
        height: MediaQuery.of(context).size.height * 0.3,
        child: DatasetListWidget(
          onSelectionChanged: (dataset) {
            setState(() {
              _selectedDataset = dataset;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            //getIt<ThemeModeSelector>().setThemeMode(_selectedTheme);
            sharedPreferences.setInt('dataset', _selectedDataset.index);
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
      alignment: Alignment.center,
    );
  }
}

class DatasetListWidget extends StatefulWidget {
  final Function(Datasets) onSelectionChanged;

  const DatasetListWidget({Key? key, required this.onSelectionChanged})
      : super(key: key);

  @override
  State<DatasetListWidget> createState() => _DatasetListWidgetState();
}

class _DatasetListWidgetState extends State<DatasetListWidget> {
  late Datasets _selectedDataset;

  @override
  void initState() {
    super.initState();

    final idx = sharedPreferences.getInt('dataset')!;
    _selectedDataset = Datasets.values[idx];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: Datasets.values.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            Datasets.values[index].toString().split('.')[1],
            style: TextStyle(color: Colors.grey[800] as Color),
          ),
          trailing: _selectedDataset == Datasets.values[index]
              ? const Icon(
                  Icons.check,
                  color: Colors.blueAccent,
                )
              : null,
          onTap: () {
            setState(() {
              _selectedDataset = Datasets.values[index];
              widget.onSelectionChanged(_selectedDataset);
            });
          },
        );
      },
    );
  }
}
