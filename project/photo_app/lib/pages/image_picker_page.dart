import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:photo_app/pages/settings_page.dart';
import 'package:photofilters/filters/filters.dart';
import 'package:photofilters/filters/preset_filters.dart';

import '../services/colorization_service.dart';
import '../widgets/filtered_image_list_widget.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({Key? key}) : super(key: key);

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  final _picker = ImagePicker();

  late TransformationController _controller;
  TapDownDetails? _tapDownDetails;

  ColorizationStatus? _status;

  Uint8List? _imageData;
  bool _isGrayscale = false;

  @override
  void initState() {
    super.initState();

    _controller = TransformationController();
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Colorization'),
        actions: [
          PopupMenuButton(
            onSelected: (item) => _onSelectedMenuItem(item),
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
                  child: _imageData == null
                      ? const Text('No image selected.')
                      : LayoutBuilder(builder:
                          (BuildContext context, BoxConstraints constraints) {
                          return Center(
                            child: GestureDetector(
                              onLongPressStart:
                                  (LongPressStartDetails details) async {
                                RenderBox? box =
                                    context.findRenderObject() as RenderBox?;
                                Offset localPosition =
                                    box!.globalToLocal(details.globalPosition);

                                double displayWidth = constraints.maxWidth;
                                double displayHeight = constraints.maxHeight;

                                final imageSize =
                                    await _getImageSize(_imageData!);

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
                              onDoubleTapDown: (details) {
                                _tapDownDetails = details;
                              },
                              onDoubleTap: () {
                                final position = _tapDownDetails!.localPosition;

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
                              child: InteractiveViewer(
                                //clipBehavior: Clip.none,
                                //panEnabled: false,
                                //scaleEnabled: false,
                                transformationController: _controller,
                                child: Image.memory(
                                  _imageData!,
                                ),
                              ),
                            ),
                          );
                        }),
                ),
              ),
              //buildFilters(),
              const SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        Uint8List imageData = await pickedFile.readAsBytes();

                        _image = img.decodeImage(imageData);

                        if (mounted) {
                          _setImageData(imageData);
                        }
                      }
                    },
                    child: const Text('Pick an Image'),
                  ),
                  if (_isGrayscale)
                    ElevatedButton(
                      onPressed: () async {
                        Uint8List colorizedImageData =
                            await ColorizationService.colorizeImage(
                          _imageData!,
                          (status) {
                            _status = status;
                            setState(() {});
                          },
                        );

                        _setImageData(colorizedImageData);
                        _status = null;
                      },
                      child: const Text('Colorize'),
                    ),
                  if (_imageData != null && !_isGrayscale)
                    ElevatedButton(
                      onPressed: () async {
                        Uint8List grayscaleImageData =
                            await ColorizationService.grayscaleImage(
                                _imageData!);
                        if (mounted) {
                          _setImageData(grayscaleImageData);
                        }
                      },
                      child: const Text('Convert to Grayscale'),
                    ),
                  if (_imageData != null)
                    ElevatedButton(
                      onPressed: () async {
                        final imageSize = await _getImageSize(_imageData!);
                        _saveImageToGallery(
                          _imageData!,
                          imageSize.width.toInt(),
                          imageSize.height.toInt(),
                        );
                      },
                      child: const Text('Save'),
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
                Text(_modifyText()),
              ],
            )
        ],
      ),
    );
  }

  _setImageData(Uint8List data) {
    _imageData = data;
    _isGrayscale = _checkIfGrayscale(data);
    setState(() {});
  }

  bool _checkIfGrayscale(Uint8List imageData) {
    img.Image image = img.decodeImage(imageData)!;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        img.Color pixel = image.getPixel(x, y);
        int red = pixel.r.toInt();
        int green = pixel.g.toInt();
        int blue = pixel.b.toInt();

        if (red != green || red != blue || green != blue) {
          return false;
        }
      }
    }
    return true;
  }

  void _onSelectedMenuItem(int item) {
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

  img.Image? _image;
  Filter filter = presetFiltersList.first;

  Widget _buildFilters() {
    if (_image == null) return Container();

    return FilteredImageListWidget(
      filters: presetFiltersList,
      image: _image!,
      onChangedFilter: (filter) {
        setState(() {
          this.filter = filter;
        });
      },
    );
  }

  Future<Size> _getImageSize(Uint8List imageData) async {
    final imageCodec = await instantiateImageCodec(imageData);
    final FrameInfo frameInfo = await imageCodec.getNextFrame();
    return Size(
      frameInfo.image.width.toDouble(),
      frameInfo.image.height.toDouble(),
    );
  }

  Future<void> _saveImageToGallery(
      Uint8List imageData, int width, int height) async {
    final directory = await getApplicationDocumentsDirectory();
    final pathOfImage =
        await File('${directory.path}/${DateTime.now()}.png').create();
    final Uint8List bytes = imageData.buffer.asUint8List();
    await pathOfImage.writeAsBytes(bytes);
  }
}
