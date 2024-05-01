import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:main/Functions/show_dialog_signout.dart';
import 'package:sensors/sensors.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:main/Functions/snackbar.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/Screens/route.dart';
import 'package:main/constants/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({
    super.key,
  });

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> with WidgetsBindingObserver {
  final BluetoothManager _bluetoothManager = BluetoothManager._instance;

  DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _bluetoothManager.checkAndStartScan(context);
    accelerometerEvents.listen(
      (AccelerometerEvent event) {
        if (mounted) {
          setState(() {
            _bluetoothManager
                .updateAccelerometerValues([event.x, event.y, event.z]);
          });
        }
      },
    );

    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _bluetoothManager.updateGyroscopeValues([event.x, event.y, event.z]);
        });
      }
    });
  }

  @override
  void dispose() {
    _bluetoothManager.dispose();
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
              if (_bluetoothManager.isScanning)
                const CircularProgressIndicator()
              else if (_bluetoothManager.esp32Device != null)
                Text(
                  ' Device: ${_bluetoothManager.esp32Device!.name}',
                  style: const TextStyle(
                    fontFamily: "Enriqueta",
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 20),
              StreamBuilder<double>(
                stream: _bluetoothManager.distanceStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'Distance to device: ${(snapshot.data! / 100).toStringAsFixed(2)} meters',
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
              if (_bluetoothManager.esp32Device != null)
                StreamBuilder<double>(
                  stream: _bluetoothManager.angleStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Transform.rotate(
                        angle: snapshot.data!,
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
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
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
                    _bluetoothManager._navigateToGPSScreen();
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

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();

  factory BluetoothManager() {
    return _instance;
  }

  BluetoothManager._internal();

  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? _scanSubscription;
  BluetoothDevice? _esp32Device;
  BluetoothCharacteristic? _buzzerCharacteristic;
  BluetoothCharacteristic? _uuidCharacteristic;
  List<double> _accelerometerValues = [0, 0, 0];
  List<double> _gyroscopeValues = [0, 0, 0];
  bool _isBuzzerOn = false;
  bool _isScanning = false;

  final UserController _userController = Get.find<UserController>();
  String _uniqueId = '';
  int _esp32RSSI = 0;
  final StreamController<double> _distanceStreamController =
      StreamController<double>();
  final StreamController<double> _angleStreamController =
      StreamController<double>();

  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  bool get isScanning => _isScanning;
  BluetoothDevice? get esp32Device => _esp32Device;
  Stream<double> get distanceStream => _distanceStreamController.stream;
  Stream<double> get angleStream => _angleStreamController.stream;

  void checkAndStartScan(BuildContext context) async {
    bool isBluetoothEnabled = await _flutterBlue.isOn;
    if (isBluetoothEnabled) {
      _requestBluetoothPermission(context);
    } else {
      showErrorDialog(context, 'Please enable Bluetooth to use this feature.',
          'Bluetooth Required');
    }
  }

  Future<void> _requestBluetoothPermission(BuildContext context) async {
    final scanPermissionStatus = await Permission.bluetoothScan.request();
    final connectPermissionStatus = await Permission.bluetoothConnect.request();

    if (!scanPermissionStatus.isGranted) {
      showSnackBar(context, "Bluetooth Scanning Permission is not granted");
    }
    if (!connectPermissionStatus.isGranted) {
      showSnackBar(context, "Bluetooth Connection Permission is not granted");
    }
    final allPermissionsGranted =
        scanPermissionStatus.isGranted && connectPermissionStatus.isGranted;
    if (allPermissionsGranted) {
      startScan(context);
    }
  }

  void startScan(BuildContext context) {
    if (_isScanning) return;
    _isScanning = true;
    _scanSubscription = _flutterBlue.scan().listen((scanResult) {
      BluetoothDevice device = scanResult.device;
      if (device.name == 'ESP32-BLE-Server') {
        _esp32RSSI = scanResult.rssi;
        _esp32Device = device;
        _isScanning = false;
        _connectToDevice(device, context);
        _updateDirectionalIndicators(scanResult.rssi);
        _updateDistance();
      }
    }, onError: (error) {
      print('Error during scanning: $error');
      _isScanning = false;
    });
  }

  void _connectToDevice(BluetoothDevice device, BuildContext context) async {
    try {
      await device.connect();
      sendUniqueId(_uniqueId);
      print("RSSI: $_esp32RSSI");
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
        _accelerometerValues.map((e) => e * e).reduce((a, b) => a + b);
    double orientation = _gyroscopeValues[0];
    _uniqueId = _userController.uuid.value;
    if (esp32RSSI > -120) {
      if (!_isBuzzerOn) {
        _controlBuzzer(true);
        _isBuzzerOn = true;
        _showSnackbar('Buzzer activated due to strong signal strength');
      }
      if (accelerationMagnitude > 20 && orientation > 0) {
        print('Device is moving forward');
      } else if (accelerationMagnitude > 20 && orientation < 0) {
        print('Device is moving backward');
      }
    } else {
      if (_isBuzzerOn) {
        _controlBuzzer(false);
        _isBuzzerOn = false;
      }

      if (_esp32Device == null || esp32RSSI < -120) {
        print('Buzzer characteristic not found');
        _showSwitchToGPSPrompt();
      }
    }
  }

  void _updateDistance() {
    if (_esp32RSSI != 0) {
      double rssiAt1Meter = -60.0;
      double n = 2.0;
      double calculatedDistance =
          pow(10, ((rssiAt1Meter - _esp32RSSI) / (10 * n))) as double;
      _distanceStreamController.add(calculatedDistance);
    }
  }

  void _controlBuzzer(bool isOn) async {
    try {
      List<BluetoothService> services = await _esp32Device!.discoverServices();
      for (var service in services) {
        if (service.uuid == Guid(bleCharac)) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == Guid(buzzerCharc)) {
              _buzzerCharacteristic = characteristic;
              int command = isOn ? 1 : 0;
              String commandChar = command.toString();
              List<int> commandBytes = utf8.encode(commandChar);
              await _buzzerCharacteristic!.write(commandBytes);
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
      List<BluetoothService> services = await _esp32Device!.discoverServices();

      for (var service in services) {
        if (service.uuid == Guid(bleCharac)) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == Guid(uuidCharc)) {
              _uuidCharacteristic = characteristic;
              List<int> idBytes = utf8.encode(id);
              await _uuidCharacteristic!.write(idBytes);
              print('Unique ID sent: $id');
              _isBuzzerOn = true;
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
          databaseReference: _databaseReference,
          uuid: _uniqueId,
        ));
  }

  void dispose() {
    _scanSubscription?.cancel();
    _esp32Device?.disconnect();
    _distanceStreamController.close();
    _angleStreamController.close();
  }

  void updateAccelerometerValues(List<double> values) {
    _accelerometerValues = values;
  }

  void updateGyroscopeValues(List<double> values) {
    _gyroscopeValues = values;
  }
}
