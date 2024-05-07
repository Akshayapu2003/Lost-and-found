import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? buzzerCharacteristic;
  BluetoothCharacteristic? uuidCharacteristic;
  int rssi = 0;
  double distance = 0.0;
  final Map<String, String> deviceUniqueIds = {};

  void updateConnectedDevice(
    BluetoothDevice? device,
    BluetoothCharacteristic? buzzer,
    BluetoothCharacteristic? uuid,
    int rssiValue,
    double distanceValue,
  ) {
    connectedDevice = device;
    buzzerCharacteristic = buzzer;
    uuidCharacteristic = uuid;
    rssi = rssiValue;
    distance = distanceValue;
    update();
  }

  String? getUniqueIDForDevice(String deviceId) {
    return deviceUniqueIds[deviceId];
  }

  void setUniqueIDForDevice(String deviceId, String uniqueId) {
    deviceUniqueIds[deviceId] = uniqueId;
  }

  final List<BluetoothDevice> connectedDevices = [];
}
