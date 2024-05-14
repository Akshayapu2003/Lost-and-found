import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothSetupManager {
  final UserController userController = Get.find<UserController>();

  Future<void> initialize(BuildContext context) async {
    bool isBluetoothEnabled = await _checkBluetoothStatus();
    if (isBluetoothEnabled) {
      bool permissionsGranted = await _requestBluetoothPermissions(context);
      if (permissionsGranted) {
        userController.setStartScanning(true);
      } else {
        userController.setStartScanning(false);
        showSnackBar(context, "Permission is not granted");
      }
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
}
