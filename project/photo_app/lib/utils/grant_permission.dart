import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> grantPermission() async {
  bool storage = true;
  bool photos = true;

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  if (androidInfo.version.sdkInt >= 33) {
    final status = await Permission.photos.request();
    photos = status.isGranted;
  } else {
    final status = await Permission.storage.request();
    storage = status.isGranted;
  }

  return storage && photos;
}
