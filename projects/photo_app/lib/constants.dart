import 'package:flutter/material.dart';

const List<String> description = [
  'Unleash your creativity using innovative image processing algorithms! Colorize grayscale photos by manually or automatically using advanced machine learning techniques, and apply a range of convolutional and color filters. This isn\'t just a simple application, it\'s a digital canvas for your imagination. ',
  'Dive in and start creating now!',
];

const List<AssetImage> imageAssets = [
  AssetImage('assets/home_page_photos/places365_01.png'),
  AssetImage('assets/home_page_photos/celebA_01.png'),
  AssetImage('assets/home_page_photos/flowers_01.png'),
  AssetImage('assets/home_page_photos/places365_02.png'),
  AssetImage('assets/home_page_photos/celebA_02.png'),
  AssetImage('assets/home_page_photos/flowers_02.png'),
];

const String modelPlaces365 = 'colorization_model_places365.tflite';
const String modelCelebA = 'colorization_model_celebA.tflite';
const String modelFlowers = 'colorization_model_flowers.tflite';

const List<String> models = [
  modelPlaces365,
  modelCelebA,
  modelFlowers,
];
