import 'package:flutter/material.dart';
import 'package:photo_app/pages/settings_page.dart';

import 'image_picker_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  final List<String> _imageAssets = [
    'assets/home_page_photos/places365_01.png',
    'assets/home_page_photos/celebA_01.png',
    'assets/home_page_photos/flowers_01.png',
    'assets/home_page_photos/places365_02.png',
    'assets/home_page_photos/celebA_02.png',
    'assets/home_page_photos/flowers_02.png',
  ];

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..addListener(() {
            if (_animationController.isCompleted) {
              _animationController.repeat();
            }

            _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent *
                    _animationController.value);
          });

    _animationController.forward();
  }

  @override
  void dispose() {
    super.dispose();

    _animationController.dispose();
    _scrollController.dispose();
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
      body: SizedBox(
        height: MediaQuery.of(context).size.height / 2.5,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          itemCount: _imageAssets.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Image.asset(
                  _imageAssets[index],
                  fit: BoxFit.cover,
                  width: 300,
                ),
              ),
            );
          },
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
                _animationController.stop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                ).then((value) {
                  _animationController.forward();
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'pickImage',
        backgroundColor: Colors.white,
        onPressed: () {
          _animationController.stop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ImagePickerPage(),
            ),
          ).then((value) {
            _animationController.forward();
          });
        },
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}
