import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

import '../constants.dart';
import '../database/photo_db_helper.dart';
import '../database/photo_model.dart';
import '../database/save_photo_extension.dart';
import '../services/guided_colorization_online.dart';
import '../utils/show_toast.dart';
import '../utils/extensions/convert_image_to_grayscale_extension.dart';
import '../utils/extensions/get_image_size_extension.dart';
import '../widgets/color_picker_popup.dart';
import '../widgets/image_widget.dart';
import '../widgets/save_image_widget.dart';
import '../widgets/share_image_widget.dart';

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

  bool _isEyeShown = false;

  final List<Map<Point<int>, Color>> _pickedColors = [];
  Point<int> _currentCoordinates = const Point(0, 0);

  late ScrollController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ScrollController();

    _originalImageData = widget.imageData.toGrayscale();
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Guided Colorization',
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
              height: 90,
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _pickedColors.isNotEmpty
                  ? ListView.builder(
                      controller: _controller,
                      scrollDirection: Axis.horizontal,
                      itemCount: _pickedColors.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onLongPressUp: () => _removeColor(index),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      _pickedColors[index].values.first,
                                  radius: 25,
                                ),
                                Text(
                                  '(${_pickedColors[index].keys.first.x}, '
                                  '${_pickedColors[index].keys.first.y})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        guidedColorizationInstruction,
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
            const Divider(
              height: 5,
              color: Colors.grey,
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return GestureDetector(
                      onLongPressStart: (LongPressStartDetails details) =>
                          _selectCoordinate(context, constraints, details),
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
          ],
        ),
      ),
    );
  }

  void _colorPicker() {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => ColorPickerPopup(
        title: "Pick a Color",
        onPickedColor: (Color color) {
          _pickedColors.add({_currentCoordinates: color});
          if (_pickedColors.length > 1) {
            _controller.animateTo(
              _controller.position.maxScrollExtent * 10,
              duration: const Duration(milliseconds: 100),
              curve: Curves.ease,
            );
          }

          setState(() {
            _colorizeImage();
          });
        },
      ),
    );
  }

  void _selectCoordinate(context, constraints, details) async {
    RenderBox? box = context.findRenderObject() as RenderBox?;
    Offset localPosition = box!.globalToLocal(details.globalPosition);

    double displayWidth = constraints.maxWidth;
    double displayHeight = constraints.maxHeight;

    final imageSize = await _originalImageData!.getSize();

    double imageAspectRatio = imageSize.width / imageSize.height;
    double displayAspectRatio = displayWidth / displayHeight;

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
  }

  void _colorizeImage() async {
    if (_pickedColors.isEmpty) {
      _processedImageData = null;
      _isEyeShown = false;
      return;
    }

    List<List<int>> coordinates = [];
    List<List<double>> colors = [];

    for (var pickedColor in _pickedColors) {
      pickedColor.forEach((point, color) {
        coordinates.add([point.x, point.y]);

        LabColor labColor = color.toLabColor();
        final a = labColor.a.toDouble();
        final b = labColor.b.toDouble();
        colors.add([a, b]);
      });
    }

    GuidedColorizationOnline.coordinates = coordinates;
    GuidedColorizationOnline.colors = colors;

    GuidedColorizationOnline.colorize(_originalImageData!).then((image) {
      if (image != null) {
        setState(() {
          showToast("The image has been updated successfully!");
          _processedImageData = image;
          _isEyeShown = true;
        });
      }
    });
  }

  void _removeColor(index) {
    setState(() {
      _pickedColors.removeAt(index);
    });

    _colorizeImage();
  }
}
