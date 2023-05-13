import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_app/pages/settings_page.dart';
import 'package:scroll_loop_auto_scroll/scroll_loop_auto_scroll.dart';

import 'algorithm_selection_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final List<String> _imageAssets = [
    'assets/home_page_photos/places365_01.png',
    'assets/home_page_photos/celebA_01.png',
    'assets/home_page_photos/flowers_01.png',
    'assets/home_page_photos/places365_02.png',
    'assets/home_page_photos/celebA_02.png',
    'assets/home_page_photos/flowers_02.png',
  ];

  final List<Card> _images = [];

  @override
  void initState() {
    super.initState();

    for (var asset in _imageAssets) {
      _images.add(Card(
        margin: const EdgeInsets.all(10),
        child: Image.asset(
          asset,
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
          left: 10,
          right: 10,
        ),
        child: Column(
          children: [
            ScrollLoopAutoScroll(
              scrollDirection: Axis.horizontal,
              gap: 0,
              duplicateChild: 30,
              duration: const Duration(seconds: 600),
              enableScrollInput: false,
              child: Row(
                children: _images,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 20),
              child: Divider(
                height: 5,
                color: Colors.grey,
              ),
            ),
          ],
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
              onPressed: () {},
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
        onPressed: () async {
          final pickedFile =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            Uint8List imageData = await pickedFile.readAsBytes();

            if (mounted) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AlgorithmSelectionPage(imageData: imageData)));
            }
          }
        },
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}
