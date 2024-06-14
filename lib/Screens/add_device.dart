import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main/constants/constants.dart';

class AddDeviceBottomSheet extends StatelessWidget {
  final VoidCallback onScanpressed;

  const AddDeviceBottomSheet({super.key, required this.onScanpressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: addDeviceBottomSheetHeight,
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Add New Device',
            style: TextStyle(
              fontFamily: "Enriqueta",
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Please make sure your device is turned on and discoverable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Enriqueta",
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              onScanpressed;
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Scan for Devices',
              style: TextStyle(
                fontFamily: "Enriqueta",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
