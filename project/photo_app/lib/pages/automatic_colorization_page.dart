import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../enums.dart';
import '../services/colorization_service.dart';
import '../utils/shared_preferences.dart';
import '../widgets/image_widget.dart';
import '../widgets/settings/dataset_list_widget.dart';

class AutomaticColorizationPage extends StatefulWidget {
  const AutomaticColorizationPage({
    Key? key,
    required this.imageData,
  }) : super(key: key);

  final Uint8List imageData;

  @override
  State<AutomaticColorizationPage> createState() =>
      _AutomaticColorizationPageState();
}

class _AutomaticColorizationPageState extends State<AutomaticColorizationPage>
    with SingleTickerProviderStateMixin {
  Uint8List? _originalImageData;
  Uint8List? _processedImageData;

  bool _isGrayscale = false;
  bool _isEyeShown = false;

  @override
  void initState() {
    super.initState();

    _originalImageData = widget.imageData;
    _convertToGrayscale();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Image Colorization',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_processedImageData == null)
            IconButton(
              onPressed: _chooseDataset,
              tooltip: 'Choose dataset',
              icon: const Icon(Icons.dataset),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ImageWidget(
                  originalImageData: _originalImageData,
                  processedImageData: _processedImageData,
                  isEyeShown: _isEyeShown,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_isGrayscale)
                  ElevatedButton(
                    onPressed: _colorizeImage,
                    child: const Text('Colorize'),
                  ),
                if (_processedImageData != null)
                  ElevatedButton(
                    onPressed: () async {
                      _saveImageToGallery(
                        _processedImageData!,
                      );
                    },
                    child: const Text('Save to Gallery'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _chooseDataset() {
    showGeneralDialog(
        context: context,
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            const DatasetPopup(title: "Datasets"));
  }

  Future<void> _saveImageToGallery(Uint8List imageData) async {
    int index = sharedPreferences.getInt('format')!;
    String format = ImageFormats.values[index].toString().split('.')[1];

    final tempDir = await getTemporaryDirectory();
    File file =
        await File('${tempDir.path}/${DateTime.now()}.$format').create();
    file.writeAsBytesSync(imageData);

    GallerySaver.saveImage(file.path, albumName: 'Pictures');
  }

  void _convertToGrayscale() {
    final bool isGrayscale =
        ColorizationService.isImageGrayscale(_originalImageData!);

    if (!isGrayscale) {
      _originalImageData =
          ColorizationService.grayscaleImage(_originalImageData!);
    }

    _isGrayscale = true;
    setState(() {});
  }

  void _colorizeImage() async {
    _processedImageData = await ColorizationService.colorizeImage(
      _originalImageData!,
      (status) {
        print(status);
      },
    );

    _isGrayscale = false;
    _isEyeShown = true;
    setState(() {});
  }
}
