import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
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

  Uint8List? _imageData;
  bool _isGrayscale = false;

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

  ColorizationStatus? _status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Editor')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: _imageData == null
                      ? const Text('No image selected.')
                      : GestureDetector(
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
                            clipBehavior: Clip.none,
                            panEnabled: false,
                            scaleEnabled: false,
                            transformationController: _controller,
                            child: Image.memory(
                              _imageData!,
                            ),
                          ),
                        ),
                ),
              ),
              buildFilters(),
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
                            await ColorizationService.colorizeImage(_imageData!,
                                (status) {
                          _status = status;
                          setState(() {});
                        });

                        _setImageData(colorizedImageData);
                        _status = null;
                      },
                      child: const Text('Colorize Image'),
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
                      child: const Text('Convert to Grayscale Image'),
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
                Text(_status.toString()),
              ],
            )
        ],
      ),
    );
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

  Widget buildFilters() {
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
}
