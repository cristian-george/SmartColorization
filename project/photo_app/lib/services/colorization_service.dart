import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:photo_app/constants.dart';
import 'package:photo_app/utils/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

enum ColorizationStatus { initialized, loaded, applied, finished }

class ColorizationService {
  static late String model;

  static void _initializeModel() {
    switch (sharedPreferences.getInt('dataset')) {
      case 0:
        model = modelPlaces365;
        break;
      case 1:
        model = modelCelebA;
        break;
      case 2:
        model = modelFlowers;
        break;
    }
  }

  static Future<Uint8List> colorizeImage(
      Uint8List imageData, Function(ColorizationStatus) callback) async {
    _initializeModel();
    callback(ColorizationStatus.initialized);

    // Load the model
    var interpreterOptions = InterpreterOptions()
      ..useNnApiForAndroid = true
      ..threads = 8;
    final interpreter =
        await Interpreter.fromAsset(model, options: interpreterOptions);

    interpreter.invoke();

    callback(ColorizationStatus.loaded);

    // Preprocessing
    img.Image inputImage = img.decodeImage(imageData)!;

    var labImage = await _rgbToLab(inputImage);

    // Lightness in original dimension
    List<double> originalLightness =
        labImage.map((pixel) => pixel.lightness.toDouble()).toList();

    img.Image resizedImage = img.copyResize(
      inputImage,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.cubic,
    );

    labImage = await _rgbToLab(resizedImage);

    List<double> lum =
        labImage.map((pixel) => pixel.lightness.toDouble()).toList();

    var inputTensorData = lum.reshape([1, 224, 224, 1]);
    var outputTensorData =
        List.filled(1 * 224 * 224 * 2, 0.0).reshape([1, 224, 224, 2]);

    // Run the model
    interpreter.run(inputTensorData, outputTensorData);
    interpreter.close();

    callback(ColorizationStatus.applied);

    // Postprocessing
    List<LabColor> ab = outputTensorData
        .reshape([224 * 224, 2])
        .map((e) => LabColor(0.0, e[0] as double, e[1] as double))
        .toList();

    List<RgbColor> outputRgbColors = [];
    for (int y = 0; y < 224; ++y) {
      for (int x = 0; x < 224; ++x) {
        double l = lum[y * 224 + x];
        double a = ab[y * 224 + x].a * 128;
        if (a <= -128) a = -128;
        if (a >= 127) a = 127;
        double b = ab[y * 224 + x].b * 128;
        if (b <= -128) b = -128;
        if (b >= 127) b = 127;
        outputRgbColors.add(RgbColor.from(LabColor(l, a, b)));
      }
    }

    // Convert LAB colors back to RGB and create a colorized image
    img.Image resultImage = img.Image(width: 224, height: 224, numChannels: 3);

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        RgbColor rgbColor = outputRgbColors[y * 224 + x];
        resultImage.setPixelRgb(
            x, y, rgbColor.red, rgbColor.green, rgbColor.blue);
      }
    }

    img.Image result = img.copyResize(
      resultImage,
      width: inputImage.width,
      height: inputImage.height,
      interpolation: img.Interpolation.cubic,
    );

    labImage = await _rgbToLab(result);

    var newRgb = img.Image(
        width: inputImage.width, height: inputImage.height, numChannels: 3);

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        double l = originalLightness[y * inputImage.width + x];
        double a = labImage[y * inputImage.width + x].a.toDouble();
        double b = labImage[y * inputImage.width + x].b.toDouble();
        RgbColor rgbColor = RgbColor.from(LabColor(l, a, b));
        newRgb.setPixelRgb(x, y, rgbColor.red, rgbColor.green, rgbColor.blue);
      }
    }

    callback(ColorizationStatus.finished);

    // Return the colorized image as Uint8List
    return img.encodeJpg(newRgb);
  }

  static Future<Uint8List> grayscaleImage(Uint8List imageData) async {
    img.Image image = img.decodeImage(imageData)!;
    img.Image grayscaleImage = img.grayscale(image);

    return img.encodeJpg(grayscaleImage);
  }

  static Future<List<LabColor>> _rgbToLab(img.Image rgbImage) async {
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

  static Future<img.Image> _labToRgb(
      List<LabColor> labColors, int width, int height) async {
    img.Image result = img.Image(width: width, height: height, numChannels: 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        RgbColor rgbColor = labColors[y * width + x].toRgbColor();
        result.setPixelRgb(x, y, rgbColor.red, rgbColor.green, rgbColor.blue);
      }
    }

    return result;
  }
}
