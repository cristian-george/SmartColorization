import 'package:flutter/material.dart';

const List<String> applicationDescription = [
  'Unleash your creativity using innovative image processing algorithms! Colorize grayscale photos by manually or automatically using advanced machine learning techniques, and apply a range of convolutional and color filters. This isn\'t just a simple application, it\'s a digital canvas for your imagination. ',
  'Dive in and start creating now!',
];

const String guidedColorizationInstruction =
    'There is no color placed on the image yet. '
    'Please long tap anywhere on the image and open the palette button above to choose how to colorize that area in the image. '
    'To remove a color from the list, long tap on it.';

const List<AssetImage> imageAssets = [
  AssetImage('assets/home_page_photos/places365_01.png'),
  AssetImage('assets/home_page_photos/celebA_01.png'),
  AssetImage('assets/home_page_photos/flowers_01.png'),
  AssetImage('assets/home_page_photos/places365_02.png'),
  AssetImage('assets/home_page_photos/celebA_02.png'),
  AssetImage('assets/home_page_photos/flowers_02.png'),
];

const String modelPlaces365 = 'colorization_models/places365.tflite';
const String modelCelebA = 'colorization_models/celebA.tflite';
const String modelFlowers = 'colorization_models/flowers.tflite';

const List<String> models = [
  modelPlaces365,
  modelCelebA,
  modelFlowers,
];

const String host = '192.168.0.139:5000';