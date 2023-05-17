import 'package:flutter/material.dart';

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

    return const MaterialApp(
      title: 'Photo App',
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }

  _precacheImages(context) async {
    await precacheImage(
        const AssetImage("assets/home_page_photos/places365_01.png"), context);
    await precacheImage(
        const AssetImage("assets/home_page_photos/places365_02.png"), context);
    await precacheImage(
        const AssetImage("assets/home_page_photos/celebA_01.png"), context);
    await precacheImage(
        const AssetImage("assets/home_page_photos/celebA_02.png"), context);
    await precacheImage(
        const AssetImage("assets/home_page_photos/flowers_01.png"), context);
    await precacheImage(
        const AssetImage("assets/home_page_photos/flowers_02.png"), context);
  }
}
