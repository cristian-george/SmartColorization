import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences sharedPreferences;

enum Themes {
  light,
  dark,
  automatic,
}

enum Datasets {
  places365,
  celebA,
  flowers,
}

enum ImageFormats {
  png,
  jpg,
  jpeg,
  tiff,
  gif,
}

initSharedPreferences() {
  if (!sharedPreferences.containsKey('theme')) {
    sharedPreferences.setInt('theme', Themes.automatic.index);
  }

  if (!sharedPreferences.containsKey('dataset')) {
    sharedPreferences.setInt('dataset', Datasets.places365.index);
  }

  if (!sharedPreferences.containsKey('format')) {
    sharedPreferences.setInt('format', ImageFormats.png.index);
  }
}
