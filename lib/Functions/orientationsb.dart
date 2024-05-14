import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  static void showDeviceOrientationSnackbar() {
    Get.snackbar(
      'Device Orientation',
      'Please place the device flat on a surface in such a way that arrow is steady for accurate positioning.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          const Color.fromARGB(255, 132, 129, 129).withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
