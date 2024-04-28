import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:main/Functions/show_dialog_signout.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/Screens/route.dart';
import 'package:main/constants/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors/sensors.dart';
import 'dart:math';

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key});

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
  bool isScanPermissionGranted = false;
  bool isConnectPermissionGranted = false;
  bool isCoarseLocationPermissionGranted = false;
  final databaseReference = FirebaseDatabase.instance.ref();
  bool serviceFound = false;
  bool characteristicFound = false;
  final UserController userController = Get.find<UserController>();
  String uniqueId = '';
  int esp32RSSI = 0;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    accelerometerEvents.listen(
      (AccelerometerEvent event) {
        if (mounted) {
          setState(() {
            accelerometerValues = [event.x, event.y, event.z];
          });
        }
      },
    );

    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          gyroscopeValues = [event.x, event.y, event.z];
        });
      }
    });
  }

  Future<void> _checkBluetoothStatus() async {
    bool isBluetoothEnabled = await flutterBlue.isOn;
    if (isBluetoothEnabled) {
      _requestBluetoothPermission();
    } else {
      showErrorDialog(context, 'Please enable Bluetooth to use this feature.',
          'Bluetooth Required');
    }
  }

  Future<void> _requestBluetoothPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      startScan();
    } else {
      _showPermissionRequestDialog(statuses);
    }
  }

  void _showPermissionRequestDialog(Map<Permission, PermissionStatus> statuses) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Grant Permissions'),
          content: const Text('This app requires the following permissions to function properly:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Map<Permission, PermissionStatus> updatedStatuses = await openAppSettings().then((_) async {
                  return await [
                    Permission.bluetooth,
                    Permission.bluetoothScan,
                    Permission.bluetoothConnect,
                    Permission.locationWhenInUse,
                  ].request();
                });

                if (updatedStatuses.values.every((status) => status.isGranted)) {
                  if (mounted) {
                    setState(() {
                      isBluetoothPermissionGranted = updatedStatuses[Permission.bluetooth]!.isGranted;
                      isScanPermissionGranted = updatedStatuses[Permission.bluetoothScan]!.isGranted;
                      isConnectPermissionGranted = updatedStatuses[Permission.bluetoothConnect]!.isGranted;
                      isCoarseLocationPermissionGranted = updatedStatuses[Permission.locationWhenInUse]!.isGranted;
                    });
                  }
                  startScan();
                  Navigator.of(context).pop();
                } else {
                  _showPermissionDeniedDialog();
                }
              },
              child: const Text('Grant Permissions'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showErrorDialog(
      context,
      'Please grant all required permissions to use this feature.',
      'Permissions Denied',
    );
  }

  void startScan() {
    if (mounted) {
      setState(() {
        isScanning = true;
      });
    }
    scanSubscription = flutterBlue.scan().listen(
      (scanResult) {
        BluetoothDevice device = scanResult.device;
        if (device.name == 'ESP32-BLE-Server') {
          if (!mounted) return;
          setState(() {
            esp32RSSI = scanResult.rssi;
            esp32Device = device;
            isScanning = false;
          });
          _connectToDevice(device);
          _updateDirectionalIndicators(scanResult.rssi);
          _updateDistance(scanResult.rssi);
        }
      },
      onError: (error) {
        print('Error during scanning: $error');
        if (mounted) {
          setState(() {
            isScanning = false;
          });
        }
        showErrorDialog(
          context,
          'An error occurred during Bluetooth scanning: $error',
          'Scanning Error',
        );
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      sendUniqueId(uniqueId);
    } catch (e) {
      print('Error connecting to device: $e');
      showErrorDialog(
        context,
        'Failed to connect to the device. Please try again.',
        'Connection Error',
      );
    }
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
            if (service.uuid == Guid(bleCharac)) {
              serviceFound = true;
              for (var characteristic in service.characteristics) {
                if (characteristic.uuid == Guid(buzzerCharc)) {
                  characteristicFound = true;
                  buzzerCharacteristic = characteristic;
                }
                if (characteristic.uuid == Guid(uuidCharc)) {
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
          }
        }).catchError((error) {
          print('Error discovering services: $error');
          showErrorDialog(
            context,
            'Failed to discover services on the device: $error',
            'Service Discovery Error',
          );
        });
      } else {
        _showSwitchToGPSPrompt();
      }
    }
  }

  void _updateDistance(int esp32RSSI) {
    double rssiAt1Meter = -60.0;
    double n = 2.0;
    double calculatedDistance =
        pow(10, ((rssiAt1Meter - esp32RSSI) / (10 * n))) as double;
    if (mounted) {
      setState(() {
        distance = calculatedDistance;
      });
    }
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

  @override
  void dispose() {
    scanSubscription?.cancel();
    esp32Device?.disconnect();
    super.dispose();
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
              if (esp32Device != null)
                Transform.rotate(
                  angle: _calculateArrowAngleFromRSSI(esp32RSSI),
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

  double _calculateArrowAngleFromRSSI(int rssi) {
    const double minRSSI = 0.0;
    const double maxRSSI = 7.0;
    const double minTransmitPower = -12.0;
    const double maxTransmitPower = 9.0;

    double clampedRSSI = rssi.clamp(minRSSI, maxRSSI) as double;

    double normalizedRSSI = (clampedRSSI - minRSSI) / (maxRSSI - minRSSI);
    double transmitPower = minTransmitPower +
        (normalizedRSSI * (maxTransmitPower - minTransmitPower));

    double angle = (transmitPower - minTransmitPower) /
        (maxTransmitPower - minTransmitPower) *
        pi;

    return -angle;
  }

  Stream<double> _getDistanceStream() async* {
    while (true) {
      yield distance;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
