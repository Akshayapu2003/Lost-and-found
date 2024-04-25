import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/Screens/route.dart';
import 'package:main/constants/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors/sensors.dart';
import 'dart:math';

class ItemScreen extends StatefulWidget {
  const ItemScreen({
    super.key,
  });

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubscription;
  BluetoothDevice? esp32Device;
  BluetoothCharacteristic? buzzerCharacteristic;
  BluetoothCharacteristic? uuidCharacteristic;
  List<double> accelerometerValues = [0, 0, 0];
  List<double> gyroscopeValues = [0, 0, 0];
  double distance = 0.0;
  bool isBuzzerOn = false;
  bool isScanning = false;
  bool isBluetoothPermissionGranted = false;
  final databaseReference = FirebaseDatabase.instance.ref();
  bool serviceFound = false;
  bool characteristicFound = false;
  final UserController userController = Get.find<UserController>();
  String uniqueId = '';

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        accelerometerValues = [event.x, event.y, event.z];
      });
    });

    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        gyroscopeValues = [event.x, event.y, event.z];
      });
    });
  }

  Future<void> _checkBluetoothStatus() async {
    bool isBluetoothEnabled = await flutterBlue.isOn;
    if (isBluetoothEnabled) {
      _requestBluetoothPermission();
    } else {
      _showBluetoothDialog();
    }
  }

  Future<void> _requestBluetoothPermission() async {
    final permissionStatus = await Permission.bluetooth.request();
    setState(() {
      isBluetoothPermissionGranted = permissionStatus.isGranted;
    });

    if (isBluetoothPermissionGranted) {
      startScan();
    }
  }

  void startScan() {
    setState(() {
      isScanning = true;
    });
    scanSubscription = flutterBlue.scan().listen((scanResult) {
      BluetoothDevice device = scanResult.device;
      if (device.name == 'ESP32_GPS_BLE') {
        setState(() {
          esp32Device = device;
          isScanning = false;
        });
        _updateDirectionalIndicators(scanResult.rssi);
        _updateDistance(scanResult.rssi);
      }
    }, onError: (error) {
      print('Error during scanning: $error');
      setState(() {
        isScanning = false;
      });
    });
  }

  void _updateDirectionalIndicators(int esp32RSSI) {
    double accelerationMagnitude =
        accelerometerValues.map((e) => e * e).reduce((a, b) => a + b);
    double orientation = gyroscopeValues[0];
    uniqueId = userController.uuid.value;
    if (esp32RSSI > -60) {
      if (!isBuzzerOn) {
        _controlBuzzer(true);
        isBuzzerOn = true;
        _showSnackbar('Buzzer activated due to strong signal strength');
      }
      if (accelerationMagnitude > 20 && orientation > 0) {
        print('Device is moving forward');
      } else if (accelerationMagnitude > 20 && orientation < 0) {
        print('Device is moving backward');
      }
    } else {
      if (isBuzzerOn) {
        _controlBuzzer(false);
        isBuzzerOn = false;
      }
      if (esp32Device != null) {
        esp32Device!.discoverServices().then((services) {
          for (var service in services) {
            if (service.uuid.toString() == bleCharac) {
              serviceFound = true;
              for (var characteristic in service.characteristics) {
                if (characteristic.uuid.toString() == buzzerCharc) {
                  characteristicFound = true;
                  buzzerCharacteristic = characteristic;
                }
                if (characteristic.uuid.toString() == uuidCharc) {
                  uuidCharacteristic = characteristic;
                }
              }
            }
          }
          if (serviceFound && characteristicFound) {
            sendUniqueId(uniqueId);
          }
          if (!characteristicFound) {
            print('Buzzer characteristic not found');
            _showSwitchToGPSPrompt();
          }
        });
      }
    }
  }

  void _updateDistance(int esp32RSSI) {
    double rssiAt1Meter = -60.0;
    double n = 2.0;
    double calculatedDistance =
        pow(10, ((rssiAt1Meter - esp32RSSI) / (10 * n))) as double;

    setState(() {
      distance = calculatedDistance;
    });
  }

  Future<void> _controlBuzzer(bool isOn) async {
    if (esp32Device != null && buzzerCharacteristic != null) {
      List<int> command = [isOn ? 1 : 0];
      await buzzerCharacteristic!.write(command);
      print('Buzzer is ${isOn ? 'on' : 'off'}');
    }
  }

  Future<void> sendUniqueId(String id) async {
    if (mounted && esp32Device != null && uuidCharacteristic != null) {
      List<int> idBytes = utf8.encode(id);
      await uuidCharacteristic!.write(idBytes);
      print('Unique ID sent: $id');
    }
  }

  void _showSnackbar(String message) {
    Get.snackbar('Buzzer Activated', message);
  }

  void _showSwitchToGPSPrompt() {
    Get.defaultDialog(
      title: 'Signal Strength Low',
      middleText: 'Switch to GPS for accurate navigation?',
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            _navigateToGPSScreen();
          },
          child: const Text('Switch to GPS'),
        ),
      ],
    );
  }

  void _navigateToGPSScreen() {
    Get.to(() => GoogleMapsScreen(
          databaseReference: databaseReference,
          uuid: uniqueId,
        ));
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth Required'),
          content: const Text('Please enable Bluetooth to use this feature.'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Navigation',
          style: TextStyle(
            fontFamily: "Enriqueta",
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isScanning)
                const CircularProgressIndicator()
              else if (esp32Device != null)
                Text(
                  'ESP32 Device Found: ${esp32Device!.name}',
                  style: const TextStyle(
                      fontFamily: "Enriqueta",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              const SizedBox(height: 20),
              StreamBuilder<double>(
                stream: _getDistanceStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'Distance to device: ${snapshot.data!.toStringAsFixed(2)} meters',
                      style: const TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    );
                  } else {
                    return const Text(
                      'Distance: Calculating...',
                      style: TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              Transform.rotate(
                angle: _calculateArrowAngle(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const AlertDialog(
                        backgroundColor: Colors.black,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              "Fetching...",
                              style: TextStyle(
                                fontFamily: "Enriqueta",
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.of(context).pop();
                    _navigateToGPSScreen();
                  });
                },
                icon: const Icon(Icons.location_on_outlined),
                label: const Text(
                  "Switch to GPS?",
                  style: TextStyle(
                    fontFamily: "Enriqueta",
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateArrowAngle() {
    double roll = gyroscopeValues[2];
    double pitch = gyroscopeValues[1];
    double orientation = atan2(roll, pitch);
    double degrees = orientation * (180 / pi);
    return degrees * (pi / 180);
  }

  Stream<double> _getDistanceStream() async* {
    while (true) {
      yield distance;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
