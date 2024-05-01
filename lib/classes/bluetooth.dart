import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothSetupManager {
  final StreamController<bool> _setupCompletedController =
      StreamController<bool>.broadcast();

  Stream<bool> get setupCompletedStream => _setupCompletedController.stream;

  Future<void> initialize(BuildContext context) async {
    bool isBluetoothEnabled = await _checkBluetoothStatus();
    if (isBluetoothEnabled) {
      bool permissionsGranted = await _requestBluetoothPermissions(context);
      if (permissionsGranted) {
        _setupCompletedController.sink.add(true);
      } else {
        _setupCompletedController.sink.add(false);
        showSnackBar(context, "Permission is not granted");
      }
    } else {
      _setupCompletedController.sink.add(false);
      showErrorDialog(
        context,
        'Please enable Bluetooth to use this feature.',
        'Bluetooth Required',
      );
    }
  }

  Future<bool> _checkBluetoothStatus() async {
    final flutterBlue = FlutterBlue.instance;
    return await flutterBlue.isOn;
  }

  Future<bool> _requestBluetoothPermissions(BuildContext context) async {
    final scanPermissionStatus = await Permission.bluetoothScan.request();
    final connectPermissionStatus = await Permission.bluetoothConnect.request();

    if (!scanPermissionStatus.isGranted) {
      showSnackBar(context, "Bluetooth Scanning Permission is not granted");
    }
    if (!connectPermissionStatus.isGranted) {
      showSnackBar(context, "Bluetooth Connection Permission is not granted");
    }

    return scanPermissionStatus.isGranted && connectPermissionStatus.isGranted;
  }

  void showSnackBar(BuildContext context, String message) {
    Get.snackbar('Permissions Required', message);
  }

  void showErrorDialog(BuildContext context, String message, String title) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  void dispose() {
    _setupCompletedController.close();
  }
}
