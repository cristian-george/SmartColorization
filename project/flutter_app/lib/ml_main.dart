import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/image_picker_page.dart';
import 'image_provider_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Image Colorization')),
        body: ChangeNotifierProvider(
          create: (context) => ImageProviderData(),
          child: const ImagePickerWidget(),
        ),
      ),
    );
  }
}
