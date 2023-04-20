import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageProviderData with ChangeNotifier {
  Uint8List? _imageData;
  bool _isGrayscale = false;

  Uint8List? get imageData => _imageData;

  bool get isGrayscale => _isGrayscale;

  void setImageData(Uint8List imageData) {
    _imageData = imageData;
    _isGrayscale = _checkIfGrayscale(imageData);
    notifyListeners();
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
}
