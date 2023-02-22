import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _image;
  Uint8List? _grayImage;

  Future<void> _loadImage() async {
    ImagePicker imagePicker = ImagePicker();
    var pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
    var image = await pickedImage?.readAsBytes();

    setState(() {
      _image = image;
    });
  }

  Future<void> _convertToGrayScale() async {
    var client = http.Client();
    var response = await client.post(
      Uri.parse('http://192.168.0.116:5000/convert_to_gray'),
      headers: {'Content-Type': 'application/octet-stream'},
      body: _image,
    );
    setState(() {
      _grayImage = response.bodyBytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Image Converter'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? const Text('No image selected')
                  : Image.memory(
                      _image!,
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
              const SizedBox(height: 20),
              _grayImage == null
                  ? Container()
                  : Image.memory(
                      _grayImage!,
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _loadImage,
            child: const Icon(Icons.image),
          ),
          const SizedBox(
            width: 30,
          ),
          FloatingActionButton(
            onPressed: _convertToGrayScale,
            child: const Icon(Icons.change_circle_rounded),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
