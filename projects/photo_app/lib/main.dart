import 'package:flutter/material.dart';

import 'constants.dart';
import 'utils/shared_preferences.dart';
import 'database/database_connection.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DatabaseConnection.initialize();
  sharedPreferences = await SharedPrefs.initialize();

  runApp(const PhotoApp());
}

class PhotoApp extends StatelessWidget {
  const PhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    _precacheImages(context);

    return MaterialApp(
      title: 'Photo App',
      home: const HomePage(),
      scrollBehavior: const ScrollBehavior().copyWith(overscroll: false),
      debugShowCheckedModeBanner: false,
    );
  }

  _precacheImages(context) async {
    for (final asset in imageAssets) {
      await precacheImage(asset, context);
    }
  }
}
