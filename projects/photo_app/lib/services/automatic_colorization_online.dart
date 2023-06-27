import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:photo_app/constants.dart';

import '../utils/show_toast.dart';

class AutomaticColorizationOnline {
  static int dataset = 0;

  static Future<Uint8List?> colorize(Uint8List image) async {
    final map = {
      'image': base64Encode(image),
      'dataset': dataset,
    };

    try {
      var response = await http.post(
        Uri.parse('http://$host/automatic_colorization'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(map),
      );

      if (response.statusCode != 200) {
        showToast("Cannot connect to the server!");
        return null;
      }

      return response.bodyBytes;
    } catch (connectionTimedOut) {
      showToast("Connection timed out!");
    }

    return null;
  }
}
