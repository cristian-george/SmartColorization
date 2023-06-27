import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/photo_db_helper.dart';
import '../database/photo_model.dart';
import '../database/save_photo_extension.dart';
import '../utils/extensions/convert_image_to_grayscale_extension.dart';
import '../widgets/colorization_image_widget.dart';
import '../widgets/save_image_widget.dart';
import '../widgets/share_image_widget.dart';

import '../services/automatic_colorization_local.dart';
import '../widgets/button_option_widget.dart';
import '../widgets/settings/dataset_list_widget.dart';

class AutomaticColorizationPage extends StatefulWidget {
  const AutomaticColorizationPage({
    Key? key,
    required this.imageData,
    required this.category,
  }) : super(key: key);

  final Uint8List imageData;
  final PhotoCategory category;

  @override
  State<AutomaticColorizationPage> createState() =>
      _AutomaticColorizationPageState();
}

class _AutomaticColorizationPageState extends State<AutomaticColorizationPage> {
  Uint8List? _originalImageData;
  Uint8List? _processedImageData;

  bool _isGrayscale = true;
  bool _isEyeShown = false;
  bool _isColoring = false;

  @override
  void initState() {
    super.initState();

    _originalImageData = widget.imageData.toGrayscale();
    AutomaticColorizationLocal.setInterpreter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Automatic Colorization',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          onPressed: () {
            if (_originalImageData != null && _processedImageData != null) {
              PhotoDbHelper.instance.savePhoto(
                  _originalImageData!, _processedImageData!, widget.category);
              Navigator.pop(context);
            }

            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isGrayscale && !_isColoring)
            IconButton(
              onPressed: _chooseDataset,
              tooltip: 'Choose dataset',
              icon: const Icon(Icons.dataset),
            ),
          if (_processedImageData != null)
            Row(
              children: [
                SaveImageWidget(
                  imageData: _processedImageData!,
                ),
                ShareImageWidget(
                  imageData: _processedImageData!,
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: ColorizationImageWidget(
                  originalImageData: _originalImageData,
                  processedImageData: _processedImageData,
                  isEyeShown: _isEyeShown,
                  isColoring: _isColoring,
                  onProcessedImage: (image) {
                    _processedImageData = image;
                    _isEyeShown = true;
                    _isColoring = false;
                    _isGrayscale = false;

                    Future.delayed(const Duration(milliseconds: 100), () {
                      setState(() {});
                    });
                  },
                ),
              ),
            ),
            if (_isGrayscale && !_isColoring)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Divider(
                  height: 5,
                  color: Colors.grey,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isGrayscale && !_isColoring)
                    ButtonOptionWidget(
                      text: 'Colorize image',
                      onSelected: () {
                        setState(() {
                          _isColoring = true;
                        });
                      },
                    ),
                ],
              ),
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
            const DatasetPopup(title: "Colorize...")).then((value) {
      AutomaticColorizationLocal.setInterpreter();
    });
  }

/*void _colorizeImageOnline(image) async {
    AutomaticColorizationOnline.dataset = sharedPreferences.getInt('dataset')!;
    AutomaticColorizationOnline.colorize(_originalImageData!).then((image) {
      if (image != null) {
        setState(() {
          showToast("The image has been updated successfully!");
          _processedImageData = image;
          _isGrayscale = false;
          _isEyeShown = true;
        });
      }
    });
  }*/
}
