import 'dart:typed_data';
import 'package:image/image.dart' as img;

extension ConvertToGrayscaleImage on Uint8List {
  Uint8List toGrayscale() {
    final bool isGrayscale = _isGrayscale(this);

    if (!isGrayscale) {
      return _convertToGrayscale(this);
    }

    return this;
  }

  Uint8List _convertToGrayscale(Uint8List imageData) {
    img.Image image = img.decodeImage(imageData)!;
    img.Image grayscaleImage = img.grayscale(image);

    return img.encodeJpg(grayscaleImage);
  }

  bool _isGrayscale(Uint8List imageData) {
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
