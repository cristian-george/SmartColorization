import 'package:shared_preferences/shared_preferences.dart';

import '../enums.dart';

class SharedPrefs {
  static late SharedPreferences _preferences;

  static Future<SharedPreferences> initialize() async {
    _preferences = await SharedPreferences.getInstance();

    if (!_preferences.containsKey('dataset')) {
      _preferences.setInt('dataset', Datasets.places365.index);
    }

    if (!_preferences.containsKey('format')) {
      _preferences.setInt('format', ImageFormats.png.index);
    }

    return _preferences;
  }
}

late SharedPreferences sharedPreferences;
