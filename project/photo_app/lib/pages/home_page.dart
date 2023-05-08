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

  final List<String> _imageUrls = [
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
    'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..addListener(() {
        if (_animationController.isCompleted) {
          _animationController.repeat();
        }
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent *
            _animationController.value);
      });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: SizedBox(
        height: MediaQuery.of(context).size.height / 3,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          itemCount: _imageUrls.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: InkWell(
                  onTap: () {
                    // Do something when an image is tapped
                  },
                  child: Image.network(
                    _imageUrls[index],
                    fit: BoxFit.cover,
                  ),
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
