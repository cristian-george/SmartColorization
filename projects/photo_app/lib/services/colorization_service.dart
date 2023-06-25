import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:photo_app/constants.dart';
import 'package:photo_app/utils/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

class ColorizationService {
  static late Interpreter interpreter;

  static final options = InterpreterOptions()
    ..useNnApiForAndroid = true
    ..threads = 8;

  static setInterpreter() async {
    late String model;
    final index = sharedPreferences.getInt('dataset');
    if (index != null) {
      model = models[index];
    }

    interpreter = await Interpreter.fromAsset(model, options: options);
    interpreter.invoke();
  }

  static preprocessingImage(Uint8List imageData) {
    img.Image inputImage = img.decodeImage(imageData)!;

    var labImage = _rgbToLab(inputImage);

    // Lightness in original dimension
    List<double> originalLuminosity =
        labImage.map((pixel) => pixel.lightness.toDouble()).toList();

    img.Image resizedImage = img.copyResize(
      inputImage,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.cubic,
    );

    labImage = _rgbToLab(resizedImage);

    List<double> luminosity =
        labImage.map((pixel) => pixel.lightness.toDouble()).toList();

    return {
      'image': imageData,
      'luminosity H x W': originalLuminosity,
      'luminosity 224 x 224': luminosity,
    };
  }

  static runModel(Map<String, dynamic> json) {
    final luminosity = json['luminosity 224 x 224'] as List<double>;
    var chrominance =
        List.filled(1 * 224 * 224 * 2, 0.0).reshape([1, 224, 224, 2]);

    interpreter.run(luminosity.reshape([1, 224, 224, 1]), chrominance);
    interpreter.close();

    return {
      'image': json['image'],
      'luminosity H x W': json['luminosity H x W'],
      'luminosity 224 x 224': luminosity,
      'chrominance 224 x 224': chrominance,
    };
  }

  static Uint8List postprocessingImage(Map<String, dynamic> json) {
    img.Image inputImage = img.decodeImage(json['image'] as Uint8List)!;
    var originalLuminosity = json['luminosity H x W'] as List<double>;

    var luminosity = json['luminosity 224 x 224'] as List<double>;
    var chrominance = json['chrominance 224 x 224'] as List;

    var i = 0;

    List<LabColor> outputLabColors =
        chrominance.reshape([224 * 224, 2]).map((pixel) {
      double l = luminosity[i++];
      double a = pixel[0] * 128;
      double b = pixel[1] * 128;

      if (a <= -128) a = -128;
      if (a >= 127) a = 127;

      if (b <= -128) b = -128;
      if (b >= 127) b = 127;

      return LabColor(l, a, b);
    }).toList();

    // Convert LAB colors back to RGB and create a colorized image
    img.Image resultImage = _labToRgb(outputLabColors, 224, 224);

    img.Image result = img.copyResize(
      resultImage,
      width: inputImage.width,
      height: inputImage.height,
      interpolation: img.Interpolation.cubic,
    );

    var labImage = _rgbToLab(result);

    var newRgb = img.Image(
        width: inputImage.width, height: inputImage.height, numChannels: 3);

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        double l = originalLuminosity[y * inputImage.width + x];
        double a = labImage[y * inputImage.width + x].a.toDouble();
        double b = labImage[y * inputImage.width + x].b.toDouble();
        RgbColor rgbColor = RgbColor.from(LabColor(l, a, b));
        newRgb.setPixelRgb(x, y, rgbColor.red, rgbColor.green, rgbColor.blue);
      }
    }

    return img.encodeJpg(newRgb);
  }

  static List<LabColor> _rgbToLab(img.Image rgbImage) {
    List<LabColor> result = [];
    for (int y = 0; y < rgbImage.height; y++) {
      for (int x = 0; x < rgbImage.width; x++) {
        img.Pixel pixel = rgbImage.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();
        RgbColor rgbColor = RgbColor(r, g, b);
        LabColor labColor = LabColor.fromColor(rgbColor);
        result.add(labColor);
      }
    }
    return result;
  }

  static img.Image _labToRgb(List<LabColor> labImage, int width, int height) {
    img.Image result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        RgbColor rgbColor = labImage[y * width + x].toRgbColor();
        result.setPixelRgb(x, y, rgbColor.red, rgbColor.green, rgbColor.blue);
      }
    }

    return result;
  }
}
