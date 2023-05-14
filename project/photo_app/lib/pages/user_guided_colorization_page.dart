import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/colorization_service.dart';
import '../widgets/button_option_widget.dart';
import '../widgets/image_widget.dart';
import '../widgets/settings/dataset_list_widget.dart';

class UserGuidedColorizationPage extends StatefulWidget {
  const UserGuidedColorizationPage({Key? key, required this.imageData})
      : super(key: key);

  final Uint8List imageData;

  @override
  State<UserGuidedColorizationPage> createState() =>
      _UserGuidedColorizationPageState();
}

class _UserGuidedColorizationPageState
    extends State<UserGuidedColorizationPage> {
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
          'Guided Image Colorization',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_processedImageData == null)
            IconButton(
              onPressed: _colorPicker,
              tooltip: 'Color picker',
              icon: const Icon(Icons.color_lens_outlined),
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
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return GestureDetector(
                      onLongPressStart: (LongPressStartDetails details) async {
                        RenderBox? box =
                            context.findRenderObject() as RenderBox?;
                        Offset localPosition =
                            box!.globalToLocal(details.globalPosition);

                        double displayWidth = constraints.maxWidth;
                        double displayHeight = constraints.maxHeight;

                        final imageSize =
                            await _getImageSize(_originalImageData!);

                        double imageAspectRatio =
                            imageSize.width / imageSize.height;
                        double displayAspectRatio =
                            displayWidth / displayHeight;

                        double scaleX, scaleY;

                        if (imageAspectRatio > displayAspectRatio) {
                          scaleX = displayWidth / imageSize.width;
                          scaleY = scaleX;
                        } else {
                          scaleY = displayHeight / imageSize.height;
                          scaleX = scaleY;
                        }

                        int x = (localPosition.dx / scaleX).round();
                        int y = (localPosition.dy / scaleY).round();

                        print('Image coordinates: ($x, $y)');
                      },
                      child: ImageWidget(
                        originalImageData: _originalImageData,
                        processedImageData: _processedImageData,
                        isEyeShown: _isEyeShown,
                      ),
                    );
                  },
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

  void _colorPicker() {
    showGeneralDialog(
        context: context,
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            const DatasetPopup(title: "Datasets"));
  }

  Future<Size> _getImageSize(Uint8List imageData) async {
    final imageCodec = await instantiateImageCodec(imageData);
    final FrameInfo frameInfo = await imageCodec.getNextFrame();
    return Size(
      frameInfo.image.width.toDouble(),
      frameInfo.image.height.toDouble(),
    );
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
