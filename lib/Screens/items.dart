import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:main/Functions/show_dialog_signout.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/Screens/route.dart';
import 'package:main/classes/bluetooth.dart';
import 'package:main/constants/constants.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

class BluetoothController extends GetxController {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? buzzerCharacteristic;
  BluetoothCharacteristic? uuidCharacteristic;
  int rssi = 0;
  double distance = 0.0;

  void updateConnectedDevice(
      BluetoothDevice? device,
      BluetoothCharacteristic? buzzer,
      BluetoothCharacteristic? uuid,
      int rssiValue,
      double distanceValue) {
    connectedDevice = device;
    buzzerCharacteristic = buzzer;
    uuidCharacteristic = uuid;
    rssi = rssiValue;
    distance = distanceValue;
    update();
  }
}

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key});

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> with WidgetsBindingObserver {
  final _bluetoothSetupManager = BluetoothSetupManager();
  final _bluetoothData = BluetoothData();
  DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubscription;
  StreamSubscription<BluetoothState>? bluetoothStateSubscription;
  BluetoothDevice? esp32Device;
  BluetoothCharacteristic? buzzerCharacteristic;
  BluetoothCharacteristic? uuidCharacteristic;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _buzzerCharacteristic;
  BluetoothCharacteristic? _uuidCharacteristic;
  List<double>? accelerometerValues;
  List<double>? gyroscopeValues;
  double distance = 0.0;
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
  final bluetoothController = Get.put(BluetoothController());
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _bluetoothSetupManager.initialize(context);
    isScanning = false;
    _streamSensorData();
    _checkConnectedDevice();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateDirectionalIndicators(bluetoothController.rssi);
      flutterBlue.scan().listen((scanResult) {
        _handleScanResult(scanResult);
      });
    });
    bluetoothStateSubscription =
        FlutterBlue.instance.state.listen((BluetoothState state) {
      if (state == BluetoothState.on) {
        checkAndStartScanning();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _checkConnectedDevice();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _checkConnectedDevice();
        break;
      case AppLifecycleState.detached:
        _cleanupResources();
        break;
      case AppLifecycleState.hidden:
        _checkConnectedDevice();
        break;
    }
  }

  @override
  void dispose() {
    _bluetoothData.dispose();
    scanSubscription?.cancel();
    bluetoothStateSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  void _checkConnectedDevice() async {
    if (bluetoothController.connectedDevice != null) {
      _timer;
      try {
        await bluetoothController.connectedDevice!.requestMtu(512);
        List<BluetoothService> services =
            await bluetoothController.connectedDevice!.discoverServices();
        for (var service in services) {
          if (service.uuid == Guid(bleCharac)) {
            for (var characteristic in service.characteristics) {
              if (characteristic.uuid == Guid(buzzerCharc)) {
                bluetoothController.buzzerCharacteristic = characteristic;
              } else if (characteristic.uuid == Guid(uuidCharc)) {
                bluetoothController.uuidCharacteristic = characteristic;
              }
            }
          }
        }
        sendUniqueId(uniqueId);
      } catch (e) {
        print('Error reconnecting to device: $e');
      }
    } else {
      checkAndStartScanning();
    }
  }

  void checkAndStartScanning() {
    if (!isScanning) {
      startScan();
    }
  }

  void _handleScanResult(ScanResult scanResult) {
    BluetoothDevice device = scanResult.device;
    if (device.name == 'ESP32-BLE-Server' && _connectedDevice == null) {
      _connectToDevice(device, scanResult.rssi);
    }
  }

  void startScan() {
    if (scanSubscription == null) {
      setState(() {
        isScanning = true;
      });
      scanSubscription = flutterBlue.scan().listen(
        _handleScanResult,
        onError: (error) {
          if (error.code != 'already_scanning') {
            print('Error during scanning: $error');
            setState(() {
              isScanning = false;
            });
          }
        },
      );
    }
  }

  void _connectToDevice(BluetoothDevice device, int rssi) async {
    try {
      await device.connect();
      _connectedDevice = device;

      List<BluetoothService> services =
          await _connectedDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid == Guid(bleCharac)) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == Guid(buzzerCharc)) {
              _buzzerCharacteristic = characteristic;
            } else if (characteristic.uuid == Guid(uuidCharc)) {
              _uuidCharacteristic = characteristic;
            }
          }
        }
      }

      bluetoothController.updateConnectedDevice(
        _connectedDevice,
        _buzzerCharacteristic,
        _uuidCharacteristic,
        rssi,
        distance,
      );

      sendUniqueId(uniqueId);
      print("RSSI: $rssi");
    } catch (e) {
      print('Error connecting to device: $e');
      showErrorDialog(
          context,
          'Failed to connect to the device. Please try again.',
          'Connection Error');
    }
  }

  void _updateDirectionalIndicators(int rssi) {
    double accelerationX = accelerometerValues?[0] ?? 0;
    double accelerationY = accelerometerValues?[1] ?? 0;
    double accelerationZ = accelerometerValues?[2] ?? 0;

    double accelerationMagnitude = sqrt(
        pow(accelerationX, 2) + pow(accelerationY, 2) + pow(accelerationZ, 2));
    double orientation = atan2(accelerationY, accelerationX);

    double angle =
        _calculateArrowAngleFromAccelerometerOrientation(orientation);
    _bluetoothData.updateAngle(angle);
    uniqueId = userController.uuid.value;

    if (bluetoothController.connectedDevice != null) {
      if (bluetoothController.rssi > -100) {
        _updateDistance();
      } else {
        print('Buzzer characteristic not found');
        _showSwitchToGPSPrompt();
      }
    } else {
      checkAndStartScanning();
    }
  }

  double _calculateArrowAngleFromAccelerometerOrientation(double orientation) {
    double minOrientation = -pi;
    double maxOrientation = pi;
    double minAngle = -pi / 2;
    double maxAngle = pi / 2;

    orientation = orientation.clamp(minOrientation, maxOrientation);

    double mappedAngle = lerpDouble(
          minAngle,
          maxAngle,
          (orientation - minOrientation) / (maxOrientation - minOrientation),
        ) ??
        0.0;

    return mappedAngle;
  }

  void _updateDistance() {
    if (bluetoothController.rssi != 0) {
      double rssiAt1Meter = -60.0;
      double n = 2.0;
      double calculatedDistance =
          pow(10, ((rssiAt1Meter - bluetoothController.rssi) / (10 * n)))
              as double;
      setState(() {
        distance = calculatedDistance;
      });
      bluetoothController.updateConnectedDevice(
        bluetoothController.connectedDevice,
        bluetoothController.buzzerCharacteristic,
        bluetoothController.uuidCharacteristic,
        bluetoothController.rssi,
        distance,
      );
    }
  }

  Future<void> _controlBuzzer(bool isOn, {bool shouldPrompt = false}) async {
    try {
      if (bluetoothController.buzzerCharacteristic != null) {
        if (shouldPrompt) {
          bool? confirmed = await _promptBuzzerActivation();
          if (confirmed == null || !confirmed) {
            return;
          }
        }

        int command = isOn ? 1 : 0;
        String commandChar = command.toString();
        List<int> commandBytes = utf8.encode(commandChar);
        await bluetoothController.buzzerCharacteristic!.write(commandBytes);
        print('Buzzer is ${isOn ? 'on' : 'off'}');
        _showSnackbar("Buzzer is activated");
        print('Buzzer command sent: $commandChar');
      } else {
        print('Buzzer characteristic not found');
      }
    } catch (e) {
      print('Error controlling buzzer: $e');
    }
  }

  void _initialcontrolBuzzer(bool isOn) {
    try {
      if (bluetoothController.buzzerCharacteristic != null) {
        int command = isOn ? 1 : 0;
        String commandChar = command.toString();
        List<int> commandBytes = utf8.encode(commandChar);
        bluetoothController.buzzerCharacteristic!.write(commandBytes);
        print('Buzzer is ${isOn ? 'on' : 'off'}');
        print('Buzzer command sent: $commandChar');
      } else {
        print('Buzzer characteristic not found');
      }
    } catch (e) {
      print('Error controlling buzzer: $e');
    }
  }

  Future<bool?> _promptBuzzerActivation() {
    return Get.defaultDialog<bool>(
      buttonColor: const Color.fromARGB(0, 0, 0, 0),
      title: 'Activate Buzzer',
      middleText: 'Do you want to activate the buzzer?',
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text(
            'No',
            style: TextStyle(
              fontFamily: "Enriqueta",
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text(
            'Yes',
            style: TextStyle(
              fontFamily: "Enriqueta",
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> sendUniqueId(String id) async {
    try {
      if (bluetoothController.uuidCharacteristic != null) {
        List<int> idBytes = utf8.encode(id);
        await bluetoothController.uuidCharacteristic!.write(idBytes);
        print('Unique ID sent: $id');
        _initialcontrolBuzzer(true);
      } else {
        print('Error: UUID characteristic not found');
      }
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

  void _streamSensorData() {
    accelerometerEvents.listen(
      (AccelerometerEvent event) {
        setState(() {
          accelerometerValues = [event.x, event.y, event.z];
        });
      },
    );

    gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        setState(() {
          gyroscopeValues = [event.x, event.y, event.z];
        });
      },
    );
  }

  void _stopScan() {
    if (isScanning) {
      scanSubscription?.cancel();
      isScanning = false;
      setState(() {
        isScanning = false;
      });
    }
  }

  void _cleanupResources() {
    _stopScan();
    _bluetoothData.dispose();
    bluetoothStateSubscription?.cancel();
    _connectedDevice?.disconnect();
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
              else if (bluetoothController.connectedDevice != null)
                Text(
                  ' Device: ${bluetoothController.connectedDevice?.name}',
                  style: const TextStyle(
                    fontFamily: "Enriqueta",
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Distance to device: ${(bluetoothController.distance / 100).toStringAsFixed(2)} meters',
                style: const TextStyle(
                  fontFamily: "Enriqueta",
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              if (bluetoothController.connectedDevice != null)
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
                              size: 90,
                              color: Colors.white,
                            ),
                          ),
                        );
                      } else {
                        return Transform.rotate(
                          angle: 0.0,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 90,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              const SizedBox(
                height: 20,
              ),
              TextButton.icon(
                onPressed: () {
                  _controlBuzzer(true, shouldPrompt: true);
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text(
                  "Activate Buzzer",
                  style: TextStyle(
                    fontFamily: "Enriqueta",
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
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
}
