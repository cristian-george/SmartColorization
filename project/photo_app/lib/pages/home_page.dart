import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_app/pages/edited_images_history_page.dart';
import 'package:scroll_loop_auto_scroll/scroll_loop_auto_scroll.dart';

import '../constants.dart';
import '../utils/grant_permission.dart';
import 'algorithm_selection_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _imageAssets = [
    const AssetImage('assets/home_page_photos/places365_01.png'),
    const AssetImage('assets/home_page_photos/celebA_01.png'),
    const AssetImage('assets/home_page_photos/flowers_01.png'),
    const AssetImage('assets/home_page_photos/places365_02.png'),
    const AssetImage('assets/home_page_photos/celebA_02.png'),
    const AssetImage('assets/home_page_photos/flowers_02.png'),
  ];

  final List<Card> _images = [];

  @override
  void initState() {
    super.initState();

    for (var asset in _imageAssets) {
      _images.add(Card(
        margin: const EdgeInsets.all(10),
        child: Image(
          image: asset,
          fit: BoxFit.cover,
          width: 300,
          height: 300,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Photo App',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 20,
          left: 10,
          right: 10,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 30.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.black.withAlpha(50),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blueAccent,
                      Colors.greenAccent,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          description.first,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          description.last,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ScrollLoopAutoScroll(
                scrollDirection: Axis.horizontal,
                gap: 0,
                duplicateChild: 30,
                duration: const Duration(minutes: 10),
                enableScrollInput: false,
                child: Row(
                  children: _images,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const SizedBox(
                width: 25,
                height: 25,
                child: Icon(Icons.image),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditedImagesHistoryPage()),
                ).then((value) {});
              },
            ),
            const SizedBox(width: 48.0),
            IconButton(
              icon: const SizedBox(
                width: 25,
                height: 25,
                child: Icon(Icons.settings),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ).then((value) {});
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'pickImage',
        backgroundColor: Colors.white,
        onPressed: _pickImage,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }

  _pickImage() async {
    bool mediaPermission = await grantPermission();
    if (!mediaPermission) return;

    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List imageData = await pickedFile.readAsBytes();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlgorithmSelectionPage(imageData: imageData),
          ),
        );
      }
    }
  }
}
