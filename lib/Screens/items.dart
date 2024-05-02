import 'dart:async';
import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:main/Functions/show_dialog_signout.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/classes/bluetooth.dart';
import 'package:sensors/sensors.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:main/Screens/route.dart';
import 'package:main/constants/constants.dart';

class BluetoothData {
  final StreamController<double> _angleStreamController =
      StreamController<double>.broadcast();

  Stream<double> get angleStream => _angleStreamController.stream;

  void updateAngle(double angle) {
    _angleStreamController.sink.add(angle);
  }

  void dispose() {
    _angleStreamController.close();
  }
}

class ItemScreen extends StatefulWidget {
  const ItemScreen({
    super.key,
  });

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> with WidgetsBindingObserver {
  final _bluetoothSetupManager = BluetoothSetupManager();
  final _bluetoothData = BluetoothData();
  DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubscription;
  BluetoothDevice? esp32Device;
  BluetoothCharacteristic? buzzerCharacteristic;
  BluetoothCharacteristic? uuidCharacteristic;
  List<double> accelerometerValues = [0, 0, 0];
  List<double> gyroscopeValues = [0, 0, 0];
  double distance = 0.0;
  bool controller = false;
  bool isBuzzerOn = false;
  bool isScanning = false;
  bool isBluetoothPermissionGranted = false;
  bool isScanPermissionGranted = false;
  bool isLocationPermissionGranted = false;
  bool isConnectPermissionGranted = false;
  bool isCoarsePermissionGranted = false;
  final UserController userController = Get.find<UserController>();
  String uniqueId = '';
  int esp32RSSI = 0;

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _bluetoothSetupManager.initialize(context);
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
    check();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateDirectionalIndicators(esp32RSSI);
    });
  }

  @override
  void dispose() {
    _bluetoothData.dispose();
    _timer.cancel();
    scanSubscription?.cancel();
    esp32Device?.disconnect();
    super.dispose();
  }

  check() {
    if (!controller) {
      if (userController.startScanning.value) {
        startScan();
      } else {
        print('Bluetooth setup failed');
      }
    } else {
      _updateDistance();
      _updateDirectionalIndicators(esp32RSSI);
    }
  }

  void startScan() {
    controller = true;
    if (mounted) {
      setState(() {
        isScanning = true;
      });
    }
    scanSubscription = flutterBlue.scan().listen((scanResult) {
      BluetoothDevice device = scanResult.device;
      if (device.name == 'ESP32-BLE-Server') {
        if (mounted) {
          setState(() {
            esp32RSSI = scanResult.rssi;
            esp32Device = device;
            isScanning = false;
          });
        }
        _connectToDevice(device);
        _updateDirectionalIndicators(scanResult.rssi);
        _updateDistance();
      }
    }, onError: (error) {
      print('Error during scanning: $error');
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      sendUniqueId(uniqueId);
      print("RSSI: ${esp32RSSI}");
    } catch (e) {
      print('Error connecting to device: $e');
      showErrorDialog(
          context,
          'Failed to connect to the device. Please try again.',
          'Connection Error');
    }
  }

  void _updateDirectionalIndicators(int esp32RSSI) {
    double accelerationMagnitude =
        accelerometerValues.map((e) => e * e).reduce((a, b) => a + b);
    double orientation = gyroscopeValues[0];
    double angle = _calculateArrowAngleFromOrientation(orientation);
    _bluetoothData.updateAngle(angle);
    uniqueId = userController.uuid.value;
    if (esp32RSSI > -100) {
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

      if (esp32Device == null || esp32RSSI < -100) {
        print('Buzzer characteristic not found');
        _showSwitchToGPSPrompt();
      }
    }
  }

  void _updateDistance() {
    if (esp32RSSI != 0) {
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
  }

  double _calculateArrowAngleFromOrientation(double orientation) {
    double minOrientation = -1.0;
    double maxOrientation = 1.0;
    double minAngle = -pi / 2;
    double maxAngle = pi / 2;

    orientation = orientation.clamp(minOrientation, maxOrientation);

    double mappedAngle = lerpDouble(
            minAngle,
            maxAngle,
            (orientation - minOrientation) /
                (maxOrientation - minOrientation)) ??
        0.0;

    return mappedAngle;
  }

  Future<void> _controlBuzzer(bool isOn) async {
    try {
      List<BluetoothService> services = await esp32Device!.discoverServices();
      for (var service in services) {
        if (service.uuid == Guid(bleCharac)) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == Guid(buzzerCharc)) {
              buzzerCharacteristic = characteristic;
              int command = isOn ? 1 : 0;
              String commandChar = command.toString();
              List<int> commandBytes = utf8.encode(commandChar);
              await buzzerCharacteristic!.write(commandBytes);
              print('Buzzer is ${isOn ? 'on' : 'off'}');
              print('Buzzer command sent: $commandChar');
              return;
            }
          }
        }
      }
      print('Buzzer characteristic not found');
    } catch (e) {
      print('Error controlling buzzer: $e');
    }
  }

  Future<void> sendUniqueId(String id) async {
    try {
      List<BluetoothService> services = await esp32Device!.discoverServices();

      for (var service in services) {
        if (service.uuid == Guid(bleCharac)) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == Guid(uuidCharc)) {
              uuidCharacteristic = characteristic;
              List<int> idBytes = utf8.encode(id);
              await uuidCharacteristic!.write(idBytes);
              print('Unique ID sent: $id');
              isBuzzerOn = true;
              _controlBuzzer(true);
              return;
            }
          }
        }
      }
      print('Error: UUID characteristic not found');
    } catch (e) {
      print('Error: $e');
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
                  ' Device: ${esp32Device!.name}',
                  style: const TextStyle(
                      fontFamily: "Enriqueta",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              const SizedBox(height: 20),
              Text(
                'Distance to device: ${(distance / 100).toStringAsFixed(2)} meters',
                style: const TextStyle(
                  fontFamily: "Enriqueta",
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              if (esp32Device != null)
                SizedBox(
                  width: 150,
                  height: 150,
                  child: StreamBuilder<double>(
                    stream: _bluetoothData.angleStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Transform.rotate(
                          angle: snapshot.data!,
                          child: Container(
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
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
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
}
