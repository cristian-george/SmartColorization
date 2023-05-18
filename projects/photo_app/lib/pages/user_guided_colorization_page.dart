import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:image/image.dart' as img;
import 'package:photo_app/database/photo_model.dart';
import 'package:photo_app/services/photo_extension_service.dart';

import '../database/photo_db_helper.dart';
import '../services/colorization_service.dart';
import '../widgets/button_option_widget.dart';
import '../widgets/color_picker_popup.dart';
import '../widgets/image_widget.dart';

class UserGuidedColorizationPage extends StatefulWidget {
  const UserGuidedColorizationPage({
    Key? key,
    required this.imageData,
    required this.category,
  }) : super(key: key);

  final Uint8List imageData;
  final PhotoCategory category;

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

  final List<Map<Point, Color>> _pickedColors = [];
  Point<int> _currentCoordinates = const Point(0, 0);

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
        leading: IconButton(
          onPressed: () {
            if (_originalImageData != null && _processedImageData != null) {
              PhotoDbHelper.instance.savePhoto(_originalImageData!,
                  _processedImageData!, PhotoCategory.guidedColorized);
            }

            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
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
            Container(
              alignment: Alignment.center,
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedColors.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: _pickedColors[index].values.first,
                          radius: 30,
                        ),
                        Text(
                          '(${_pickedColors[index].keys.first.x}, '
                          '${_pickedColors[index].keys.first.y})',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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

                        _currentCoordinates = Point(x, y);
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
    final color = _getColorPixelAt(_currentCoordinates);

    showGeneralDialog(
        context: context,
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            ColorPickerPopup(
              title: "Pick a Color",
              initialColor: color,
              onPickedColor: (Color color) {
                _pickedColors.add({_currentCoordinates: color});
                setState(() {});
              },
            ));
  }

  Future<Size> _getImageSize(Uint8List imageData) async {
    final imageCodec = await instantiateImageCodec(imageData);
    final FrameInfo frameInfo = await imageCodec.getNextFrame();
    return Size(
      frameInfo.image.width.toDouble(),
      frameInfo.image.height.toDouble(),
    );
  }

  Color _getColorPixelAt(Point<int> coordinates) {
    img.Image image = img.decodeImage(_originalImageData!)!;
    img.Color pixel = image.getPixel(coordinates.x, coordinates.y);

    int r = pixel.r.toInt();
    int g = pixel.g.toInt();
    int b = pixel.b.toInt();
    LabColor labColor = RgbColor(r, g, b).toLabColor();

    final lightness = labColor.lightness;
    print('Lightness: $lightness');

    RgbColor rgbColor = LabColor(lightness, 0, 0).toRgbColor();
    return Color.fromARGB(255, rgbColor.red, rgbColor.green, rgbColor.blue);
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
