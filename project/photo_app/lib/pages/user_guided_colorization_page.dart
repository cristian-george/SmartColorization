import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../enums.dart';
import '../services/colorization_service.dart';
import '../utils/shared_preferences.dart';
import '../widgets/settings/dataset_list_widget.dart';

class UserGuidedColorizationPage extends StatefulWidget {
  const UserGuidedColorizationPage({Key? key, required this.imageData})
      : super(key: key);

  final Uint8List imageData;

  @override
  State<UserGuidedColorizationPage> createState() =>
      _UserGuidedColorizationPageState();
}

class _UserGuidedColorizationPageState extends State<UserGuidedColorizationPage>
    with SingleTickerProviderStateMixin {
  late TransformationController _controller;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  final double _minScale = 1;
  final double _maxScale = 4;

  OverlayEntry? entry;

  ColorizationStatus? _status;

  Uint8List? _originalImageData;
  Uint8List? _processedImageData;

  bool _isGrayscale = false;
  bool _isEyeShown = false;

  @override
  void initState() {
    super.initState();

    _originalImageData = widget.imageData;
    _convertToGrayscale();

    _controller = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )
      ..addListener(() => _controller.value = _animation!.value)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _removeOverlay();
        }
      });
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
    _animationController.dispose();
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          return GestureDetector(
                            onLongPressStart:
                                (LongPressStartDetails details) async {
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
                              double offsetX = 0, offsetY = 0;

                              if (imageAspectRatio > displayAspectRatio) {
                                scaleX = displayWidth / imageSize.width;
                                scaleY = scaleX;
                                offsetY = (displayHeight -
                                        (imageSize.height * scaleY)) /
                                    2;
                              } else {
                                scaleY = displayHeight / imageSize.height;
                                scaleX = scaleY;
                                offsetX = (displayWidth -
                                        (imageSize.width * scaleX)) /
                                    2;
                              }

                              int x = ((localPosition.dx - offsetX) / scaleX)
                                  .round();
                              int y = ((localPosition.dy - offsetY) / scaleY)
                                  .round();

                              print('Image coordinates: ($x, $y)');
                            },
                            child: _buildImage(),
                          );
                        },
                      ),
                      if (_processedImageData != null)
                        GestureDetector(
                          onTapDown: (details) {
                            setState(() {
                              _isEyeShown = false;
                            });
                          },
                          onTapUp: (details) {
                            setState(() {
                              _isEyeShown = true;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            padding: const EdgeInsets.all(2.5),
                            color: Colors.black.withOpacity(0.5),
                            child: Icon(
                              _isEyeShown
                                  ? Icons.remove_red_eye_outlined
                                  : Icons.remove_red_eye_sharp,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
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
          if (_status != null && _status != ColorizationStatus.finished)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                Container(
                  height: 50,
                  color: Colors.white.withOpacity(0.5),
                  child: Text(_modifyText()),
                ),
              ],
            )
        ],
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

  String _modifyText() {
    switch (_status) {
      case ColorizationStatus.initialized:
        return "Initialize interpreter";
      case ColorizationStatus.loaded:
        return "Loaded model";
      case ColorizationStatus.applied:
        return "Image colorized";
      case ColorizationStatus.finished:
        break;
      default:
        break;
    }

    return "";
  }

  Future<Size> _getImageSize(Uint8List imageData) async {
    final imageCodec = await instantiateImageCodec(imageData);
    final FrameInfo frameInfo = await imageCodec.getNextFrame();
    return Size(
      frameInfo.image.width.toDouble(),
      frameInfo.image.height.toDouble(),
    );
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

  Widget _buildImage() {
    return Builder(
      builder: (context) => InteractiveViewer(
        clipBehavior: Clip.none,
        transformationController: _controller,
        panEnabled: false,
        minScale: _minScale,
        maxScale: _maxScale,
        onInteractionStart: (details) {
          if (details.pointerCount < 2) return;

          if (entry == null) {
            _showOverlay(context);
          }
        },
        onInteractionEnd: (details) {
          if (details.pointerCount != 1) return;

          _resetAnimation();
        },
        child: Image.memory(
          !_isEyeShown ? _originalImageData! : _processedImageData!,
        ),
      ),
    );
  }

  void _resetAnimation() {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.forward(from: 0);
  }

  void _showOverlay(BuildContext context) {
    final renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = MediaQuery.of(context).size;

    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.white),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: size.width,
              child: _buildImage(),
            ),
          ],
        );
      },
    );

    final overlay = Overlay.of(context);
    overlay.insert(entry!);
  }

  void _removeOverlay() {
    entry?.remove();
    entry = null;
  }

  void _convertToGrayscale() async {
    final bool isGrayscale =
        ColorizationService.isImageGrayscale(_originalImageData!);

    if (!isGrayscale) {
      _originalImageData =
          await ColorizationService.grayscaleImage(_originalImageData!);
    }

    _isGrayscale = true;
    setState(() {});
  }

  void _colorizeImage() async {
    _processedImageData = await ColorizationService.colorizeImage(
      _originalImageData!,
      (status) {
        _status = status;
        setState(() {});
      },
    );

    _isGrayscale = false;
    _isEyeShown = true;
    _status = null;
    setState(() {});
  }
}
