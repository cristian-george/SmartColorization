import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_app/widgets/save_image_widget.dart';

import '../services/colorization_service.dart';
import '../widgets/button_option_widget.dart';
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

class _AutomaticColorizationPageState extends State<AutomaticColorizationPage> {
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
          _processedImageData == null
              ? IconButton(
                  onPressed: _chooseDataset,
                  tooltip: 'Choose dataset',
                  icon: const Icon(Icons.dataset),
                )
              : SaveImageWidget(
                  imageData: _processedImageData!,
                ),
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
            if (_isGrayscale)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Divider(
                  height: 5,
                  color: Colors.grey,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isGrayscale)
                    ButtonOptionWidget(
                      text: 'Colorize image',
                      onSelected: _colorizeImage,
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
            const DatasetPopup(title: "Datasets"));
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
