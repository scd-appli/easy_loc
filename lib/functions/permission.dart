import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> grantAccess() async {
  if (Platform.isAndroid) {
    return await _grantAccessAndroid();
  }

  return true;
}

Future<bool> _grantAccessAndroid() async {
  bool permissionGranted = false;

  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  final int sdkInt = androidInfo.version.sdkInt;

  if (sdkInt >= 30) {
    // Android 11 (API 30) or higher
    PermissionStatus status = await Permission.manageExternalStorage.status;
    debugPrint("Android 11+: Initial manageExternalStorage status: $status");
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      debugPrint(
        "Android 11+: Status after manageExternalStorage request: $status",
      );
    }
    if (status.isGranted) {
      permissionGranted = true;
    }
  } else {
    // Android 10 (API 29) or older (down to your minSdk)
    PermissionStatus status = await Permission.storage.status;
    debugPrint("Android 10 or older: Initial storage status: $status");
    if (!status.isGranted) {
      status = await Permission.storage.request();
      debugPrint("Android 10 or older: Status after storage request: $status");
    }
    if (status.isGranted) {
      permissionGranted = true;
    }
  }

  return permissionGranted;
}
