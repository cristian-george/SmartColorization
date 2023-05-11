import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_app/pages/settings_page.dart';

import '../services/colorization_service.dart';
import '../utils/shared_preferences.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({Key? key}) : super(key: key);

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();

  late TransformationController _controller;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  final double _minScale = 1;
  final double _maxScale = 4;

  OverlayEntry? entry;

  TapDownDetails? _tapDownDetails;

  ColorizationStatus? _status;

  Uint8List? _originalImageData;
  Uint8List? _processedImageData;

  bool _isGrayscale = false;
  bool _isEyeShown = false;

  @override
  void initState() {
    super.initState();

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
      appBar: AppBar(
        title: const Text('Image Colorization'),
        actions: [
          PopupMenuButton(
            onSelected: (item) => _onSelectedPopupMenuItem(item),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: _originalImageData == null
                      ? const Text('No image selected.')
                      : Stack(
                          children: [
                            LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                return GestureDetector(
                                  onLongPressStart:
                                      (LongPressStartDetails details) async {
                                    RenderBox? box = context.findRenderObject()
                                        as RenderBox?;
                                    Offset localPosition = box!
                                        .globalToLocal(details.globalPosition);

                                    double displayWidth = constraints.maxWidth;
                                    double displayHeight =
                                        constraints.maxHeight;

                                    final imageSize = await _getImageSize(
                                        _originalImageData!);

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

                                    int x =
                                        ((localPosition.dx - offsetX) / scaleX)
                                            .round();
                                    int y =
                                        ((localPosition.dy - offsetY) / scaleY)
                                            .round();

                                    print('Image coordinates: ($x, $y)');
                                  },
                                  onDoubleTapDown: (details) {
                                    _tapDownDetails = details;
                                  },
                                  onDoubleTap: () {
                                    final position =
                                        _tapDownDetails!.localPosition;

                                    const double scale = 3;
                                    final x = -position.dx * (scale - 1);
                                    final y = -position.dy * (scale - 1);
                                    final zoomed = Matrix4.identity()
                                      ..translate(x, y)
                                      ..scale(scale);

                                    final value = _controller.value.isIdentity()
                                        ? zoomed
                                        : Matrix4.identity();
                                    _controller.value = value;
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
                //crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      _processedImageData = null;
                      _isEyeShown = false;

                      final pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        Uint8List imageData = await pickedFile.readAsBytes();

                        if (mounted) {
                          final bool isGrayscale =
                              ColorizationService.isImageGrayscale(imageData);
                          if (isGrayscale) return;

                          _convertToGrayscale(imageData);
                        }
                      }
                    },
                    child: const Text('Pick an Image'),
                  ),
                  if (_isGrayscale)
                    ElevatedButton(
                      onPressed: () async {
                        _processedImageData =
                            await ColorizationService.colorizeImage(
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
                      },
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
                Container(
                  color: Colors.white30,
                ),
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

  void _onSelectedPopupMenuItem(int item) {
    switch (item) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
        break;
    }
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

/*  img.Image? _image;
  Filter filter = presetFiltersList.first;

  Widget _buildFilters() {
    if (_originalImageData == null) return Container();

    _image = img.decodeImage(_originalImageData!);

    return FilteredImageListWidget(
      filters: presetFiltersList,
      image: _image!,
      onChangedFilter: (filter) {
        setState(() {
          this.filter = filter;
        });
      },
    );
  }*/

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

  void _convertToGrayscale(Uint8List imageData) async {
    final Uint8List grayscaleImageData =
        await ColorizationService.grayscaleImage(imageData);
    if (mounted) {
      _originalImageData = grayscaleImageData;
      _isGrayscale = true;
      setState(() {});
    }
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
}
