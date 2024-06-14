import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:main/Functions/orientationsb.dart';
import 'package:main/Functions/show_dialog_signout.dart';
import 'package:main/Screens/add_device.dart';
import 'package:main/Screens/bottomsheet.dart';
import 'package:main/Screens/direction.dart';
import 'package:main/Screens/route.dart';
import 'package:main/classes/bluetooth.dart';
import 'package:main/constants/constants.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';

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

class _ItemScreenState extends State<ItemScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _bluetoothSetupManager = BluetoothSetupManager();
  final _bluetoothData = BluetoothData();
  final databaseRef = FirebaseDatabase.instance.ref();
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
  String uniqueId = '';
  int esp32RSSI = 0;
  final bluetoothController = Get.put(BluetoothController());
  late Timer _timer;
  bool enabled = true;
  Uuid uuid = const Uuid();
  final devicesMap = <String, Map<String, dynamic>>{};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _arrowUpAnimationController;
  @override
  void initState() {
    super.initState();
    _arrowUpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    bluetoothStateSubscription =
        FlutterBlue.instance.state.listen(_handleBluetoothStateChange);
  }

  void initializeScreen() {
    _bluetoothSetupManager.initialize(context);
    isScanning = false;
    _streamSensorData();
    _checkConnectedDevice();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateDistance();
    });

    final devicesRef = databaseRef.child('devices');
    devicesRef.onValue.listen(
      (event) {
        final snapshot = event.snapshot;
        devicesMap.clear();
        for (var childSnap in snapshot.children) {
          final deviceData = childSnap.value as Map<dynamic, dynamic>;
          devicesMap[childSnap.key!] = {
            'name': deviceData['name'],
            'macAddress': deviceData['macAddress'],
            'uniqueId': deviceData['uniqueId'],
          };
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
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
    _arrowUpAnimationController.dispose();
    _timer.cancel();
    _streamSensorData();
    super.dispose();
  }

  void _handleBluetoothStateChange(BluetoothState state) {
    if (state == BluetoothState.on) {
      initializeScreen();
    } else {
      showBluetoothOffSnackbar();
    }
  }

  void showBluetoothOffSnackbar() {
    Get.snackbar(
      'Bluetooth is Off',
      'Please turn on Bluetooth to use this app.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      backgroundColor: const Color.fromARGB(255, 124, 122, 122),
    );
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
    print('_handleScanResult called for device: ${scanResult.device.name}');
    BluetoothDevice device = scanResult.device;
    bluetoothController.rssi = scanResult.rssi;
    if (device.name == 'ESP32-BLE-Server' &&
        bluetoothController.connectedDevice == null) {
      _connectToDevice(device, scanResult.rssi);
      scanSubscription?.cancel(); // Stop scanning once we find our device
      setState(() {
        isScanning = false;
      });
    }
  }

  void startScan() {
    print('startScan() called');
    _stopScan();

    setState(() {
      isScanning = true;
    });

    scanSubscription =
        flutterBlue.scan(timeout: const Duration(seconds: 10)).listen(
      (scanResult) {
        print('Device found: ${scanResult.device.name}');
        _handleScanResult(scanResult);
      },
      onDone: () {
        print('Scan finished');
        setState(() {
          isScanning = false;
          if (bluetoothController.connectedDevice == null) {
            bluetoothController.updateConnectedDevice(null, null, null, 0, 0.0);
          }
        });
      },
      onError: (error) {
        print('Error during scanning: $error');
        setState(() {
          isScanning = false;
        });
      },
    );
  }

  void _connectToDevice(BluetoothDevice device, int rssi) async {
    try {
      await device.connect();
      _connectedDevice = device;
      SnackbarHelper.showDeviceOrientationSnackbar();
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

      final deviceMacAddress = _connectedDevice!.id.id;
      final existingUniqueId = devicesMap[deviceMacAddress]?['uniqueId'];

      if (existingUniqueId != null) {
        uniqueId = existingUniqueId;
        sendUniqueId(uniqueId);
        enabled = false;
      } else {
        if (enabled) {
          uniqueId = uuid.v4();
          sendUniqueId(uniqueId);
          storeDeviceInfo(
            _connectedDevice!.name,
            deviceMacAddress,
            uniqueId,
          );
          enabled = false;
        }
      }

      print("RSSI: $rssi");
    } catch (e) {
      print('Error connecting to device: $e');
      showErrorDialog(
          context,
          'Failed to connect to the device. Please try again.',
          'Connection Error');
    }
  }

  void _updateDistance() {
    if (bluetoothController.rssi != 0) {
      double rssiAt1Meter = -60.0;
      double n = 2.0;
      double calculatedDistance =
          pow(10, ((rssiAt1Meter - bluetoothController.rssi) / (10 * n)))
              as double;
      if (mounted) {
        setState(() {
          distance = calculatedDistance;
        });
      }
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
        bool? confirmed;
        if (shouldPrompt) {
          if (isOn) {
            confirmed = await _promptBuzzerActivation();
          } else {
            confirmed = await _promptDeBuzzerActivation();
          }
          if (confirmed == null || !confirmed) {
            return;
          }
        }
        int command = isOn ? 1 : 0;
        String commandChar = command.toString();
        List<int> commandBytes = utf8.encode(commandChar);
        await bluetoothController.buzzerCharacteristic!.write(commandBytes);
        print('Buzzer is ${isOn ? 'on' : 'off'}');
        _showSnackbar("Buzzer is ${isOn ? 'activated' : 'deactivated'}");
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

  Future<bool?> _promptDeBuzzerActivation() {
    return Get.defaultDialog<bool>(
      buttonColor: const Color.fromARGB(0, 0, 0, 0),
      title: 'Deactivate Buzzer',
      middleText: 'Do you want to deactivate the buzzer?',
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
    Get.snackbar(
      'Buzzer Message',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor:
          const Color.fromARGB(255, 132, 129, 129).withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _navigateToGPSScreen() {
    Get.to(() => GoogleMapsScreen(
          databaseReference: databaseRef,
          uuid: uniqueId,
        ));
  }

  void _streamSensorData() {
    accelerometerEvents.listen(
      (AccelerometerEvent event) {
        if (mounted) {
          setState(() {
            accelerometerValues = [event.x, event.y, event.z];
          });
        }
      },
    );

    gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        if (mounted) {
          setState(() {
            gyroscopeValues = [event.x, event.y, event.z];
          });
        }
      },
    );
  }

  void _stopScan() {
    if (isScanning) {
      scanSubscription?.cancel();
      isScanning = false;
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  void _cleanupResources() {
    _stopScan();
    _bluetoothData.dispose();
    bluetoothStateSubscription?.cancel();
    _connectedDevice?.disconnect();
  }

  void storeDeviceInfo(String deviceName, String macAddress, String uniqueId) {
    final devicesRef = databaseRef.child('devices');
    devicesRef.child(macAddress).set({
      'name': deviceName,
      'macAddress': macAddress,
      'uniqueId': uniqueId,
    });
  }

  void _handleScanPressed({bool fromBottomSheet = false}) async {
    print('_handleScanPressed called, fromBottomSheet: $fromBottomSheet');

    _stopScan();

    // Disconnect current device
    if (bluetoothController.connectedDevice != null) {
      try {
        await bluetoothController.connectedDevice!.disconnect();
        print('Device disconnected successfully');
      } catch (e) {
        print('Error disconnecting device: $e');
      }
    }
    setState(() {
      bluetoothController.updateConnectedDevice(null, null, null, 0, 0.0);
      uniqueId = '';
      enabled = true;
      accelerometerValues = null;
      gyroscopeValues = null;
      distance = 0.0;
      isBuzzerOn = false;
      esp32RSSI = 0;
      isScanning = true;
    });

    scanSubscription?.cancel();
    bluetoothStateSubscription?.cancel();
    _timer.cancel();

    _bluetoothSetupManager.initialize(context);
    _streamSensorData();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateDistance();
    });

    await Future.delayed(const Duration(seconds: 50));
    startScan();
  }

  void _rebuildFromHomeScreen() {
    print('_rebuildFromHomeScreen called');
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return AddDeviceBottomSheet(
          onScanpressed: () {
            print(
                'onScanPressed callback triggered from _rebuildFromHomeScreen');
            Navigator.pop(context); // Explicitly close the bottom sheet
            _handleScanPressed(fromBottomSheet: true);
          },
        );
      },
    );
  }

  void _showDeviceInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return DeviceInfoBottomSheet(
              devices: devicesMap.values.toList(),
              onDeviceSelected: (selectedDevice) {
                String selectedDeviceMacAddress = selectedDevice['macAddress'];
                if (bluetoothController.connectedDevice != null &&
                    bluetoothController.connectedDevice!.id.id ==
                        selectedDeviceMacAddress) {
                  print('Selected device is already connected');
                }

                Navigator.of(context).pop();
              },
              scrollController: scrollController,
              rebuildParent: _rebuildFromHomeScreen,
              onDeviceRename: updateDeviceName,
            );
          },
        );
      },
    );
  }

  void updateDeviceName(String newName, String macAddress) {
    final deviceRef = databaseRef.child('devices/$macAddress');
    deviceRef.update({'name': newName});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _handleScanPressed,
          ),
        ],
      ),
      body: Container(
        color: Colors.black87,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isScanning
                        ? const Column(
                            children: [
                              Text(
                                'Searching for devices',
                                style: TextStyle(
                                  fontFamily: "Enriqueta",
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              CircularProgressIndicator(),
                            ],
                          )
                        : Text(
                            'Device: ${bluetoothController.connectedDevice?.name}',
                            style: const TextStyle(
                              fontFamily: "Enriqueta",
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                    if (bluetoothController.connectedDevice != null)
                      const SizedBox(height: 20),
                    if (bluetoothController.connectedDevice != null)
                      Text(
                        'Distance to device: ${(bluetoothController.distance / 100).toStringAsFixed(2)} meters',
                        style: const TextStyle(
                          fontFamily: "Enriqueta",
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    if (bluetoothController.connectedDevice != null)
                      const SizedBox(height: 20),
                    if (bluetoothController.connectedDevice != null)
                      const SizedBox(
                        width: 150,
                        height: 150,
                        child: IndoorPositioning(),
                      ),
                    if (bluetoothController.connectedDevice != null)
                      const SizedBox(
                        height: 20,
                      ),
                    if (bluetoothController.connectedDevice != null)
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
                    if (bluetoothController.connectedDevice != null)
                      const SizedBox(
                        height: 20,
                      ),
                    if (bluetoothController.connectedDevice != null)
                      TextButton.icon(
                        onPressed: () {
                          _controlBuzzer(false, shouldPrompt: true);
                        },
                        icon: const Icon(Icons.notifications_off),
                        label: const Text(
                          "Deactivate Buzzer",
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
                      icon: const Icon(Icons.navigation),
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
            DeviceInfoBottomSheet(
              devices: devicesMap.values.toList(),
              onDeviceSelected: (selectedDevice) {},
              scrollController: null,
              rebuildParent: _rebuildFromHomeScreen,
              onDeviceRename: updateDeviceName,
            ),
            GestureDetector(
              onTap: () => _showDeviceInfoBottomSheet(context),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: Tween<double>(
                      begin: 2.0,
                      end: 1.2,
                    ).animate(
                      CurvedAnimation(
                        parent: _arrowUpAnimationController,
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    'Touch for more options',
                    style: TextStyle(
                      fontFamily: "Enriqueta",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
