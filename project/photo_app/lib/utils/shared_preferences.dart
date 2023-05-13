import 'package:shared_preferences/shared_preferences.dart';

import '../enums.dart';

late SharedPreferences sharedPreferences;

void initSharedPreferences() {
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
