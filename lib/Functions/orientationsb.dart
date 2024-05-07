import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  static void showDeviceOrientationSnackbar() {
    Get.snackbar(
      'Device Orientation',
      'Please place the device flat on a surface for accurate positioning.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
