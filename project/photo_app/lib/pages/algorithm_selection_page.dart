import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_app/pages/user_guided_colorization_page.dart';
import 'package:photo_app/utils/convolution_filters.dart';
import 'package:scroll_loop_auto_scroll/scroll_loop_auto_scroll.dart';

import '../utils/color_filters.dart';
import 'automatic_colorization_page.dart';
import 'image_filters_page.dart';

class AlgorithmSelectionPage extends StatefulWidget {
  const AlgorithmSelectionPage({Key? key, required this.imageData})
      : super(key: key);

  final Uint8List imageData;

  @override
  State<AlgorithmSelectionPage> createState() => _AlgorithmSelectionPageState();
}

class _AlgorithmSelectionPageState extends State<AlgorithmSelectionPage>
    with SingleTickerProviderStateMixin {
  late TransformationController _controller;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  final double _minScale = 1;
  final double _maxScale = 4;

  OverlayEntry? entry;

  Uint8List? _originalImageData;
  Uint8List? _croppedImageData;

  bool _isCropped = false;

  @override
  void initState() {
    super.initState();

    _controller = TransformationController();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() => _controller.value = _animation!.value)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _removeOverlay();
        }
      });

    _originalImageData = widget.imageData;
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
          'Algorithm Selection',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _cropImage,
            tooltip: 'Crop',
            icon: const Icon(Icons.crop),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: _buildImage(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Divider(
                    height: 5,
                    color: Colors.grey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ScrollLoopAutoScroll(
                    scrollDirection: Axis.horizontal,
                    gap: 0,
                    duplicateChild: 10,
                    duration: const Duration(minutes: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AlgorithmOption(
                          text: 'Automatic Image Colorization',
                          onSelected: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AutomaticColorizationPage(
                                  imageData: _isCropped
                                      ? _croppedImageData!
                                      : _originalImageData!,
                                ),
                              ),
                            );
                          },
                        ),
                        AlgorithmOption(
                          text: 'User Guided Image Colorization',
                          onSelected: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserGuidedColorizationPage(
                                  imageData: _isCropped
                                      ? _croppedImageData!
                                      : _originalImageData!,
                                ),
                              ),
                            );
                          },
                        ),
                        AlgorithmOption(
                          text: 'Image Color Filters',
                          onSelected: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageFiltersPage(
                                  title: 'Image Color Filters',
                                  imageData: _isCropped
                                      ? _croppedImageData!
                                      : _originalImageData!,
                                  filters: colorFilters,
                                ),
                              ),
                            );
                          },
                        ),
                        AlgorithmOption(
                          text: 'Image Convolution Filters',
                          onSelected: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageFiltersPage(
                                  title: 'Image Convolution Filters',
                                  imageData: _isCropped
                                      ? _croppedImageData!
                                      : _originalImageData!,
                                  filters: convolutionFilters,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    _isCropped = false;
    _croppedImageData = _originalImageData;

    final tempDir = await getTemporaryDirectory();
    File file = await File('${tempDir.path}/image.jpg').create();
    file.writeAsBytesSync(_originalImageData!);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black,
          activeControlsWidgetColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
      ],
    );

    if (croppedFile != null) {
      _isCropped = true;
      _croppedImageData = await croppedFile.readAsBytes();
    }

    setState(() {});
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
          !_isCropped ? _originalImageData! : _croppedImageData!,
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

class AlgorithmOption extends StatelessWidget {
  const AlgorithmOption({
    Key? key,
    required this.text,
    required this.onSelected,
  }) : super(key: key);

  final String text;
  final Function() onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.black.withAlpha(25),
      ),
      height: 40,
      margin: const EdgeInsets.only(left: 20),
      child: TextButton(
        onPressed: onSelected,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
