import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:main/Screens/route.dart';
import 'package:main/constants/constants.dart';
import 'package:sensors/sensors.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key});

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubscription;
  BluetoothDevice? esp32Device;
  BluetoothCharacteristic? buzzerCharacteristic;
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  List<double> accelerometerValues = [0, 0, 0];
  List<double> gyroscopeValues = [0, 0, 0];

  double distance = 0.0;
  bool isBuzzerOn = false;
  bool isLowSignalPromptShown = false;
  bool isScanning = false;
  bool isAppOpen = false;
  @override
  void initState() {
    super.initState();
    _initializeApp();
    startScan();
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

  Future<void> _initializeApp() async {
    await Firebase.initializeApp();
    databaseReference.child('appSignal').onValue.listen((event) {
      setState(() {
        isAppOpen = event.snapshot.value == 'open';
      });
    });
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
        updateDirectionalIndicators(scanResult.rssi);
        updateDistance(scanResult.rssi);
      }
    });
  }

  void updateDirectionalIndicators(int esp32RSSI) {
    double accelerationMagnitude =
        accelerometerValues.map((e) => e * e).reduce((a, b) => a + b);
    double orientation = gyroscopeValues[0];

    if (esp32RSSI > -60) {
      if (!isBuzzerOn) {
        controlBuzzer(true);
        isBuzzerOn = true;
        showSnackbar('Buzzer activated due to strong signal strength');
      }
      if (accelerationMagnitude > 20 && orientation > 0) {
        print('Device is moving forward');
      } else if (accelerationMagnitude > 20 && orientation < 0) {
        print('Device is moving backward');
      }
    } else {
      if (isBuzzerOn) {
        controlBuzzer(false);
        isBuzzerOn = false;
      }
      if (!isLowSignalPromptShown) {
        showSwitchToGPSPrompt();
        isLowSignalPromptShown = true;
      }
    }
  }

  void updateDistance(int esp32RSSI) {
    double rssiAt1Meter = -60.0;
    double n = 2.0;
    double calculatedDistance =
        pow(10, ((rssiAt1Meter - esp32RSSI) / (10 * n))) as double;

    setState(() {
      distance = calculatedDistance;
    });
  }

  Future<void> controlBuzzer(bool isOn) async {
    if (esp32Device != null) {
      List<BluetoothService> services = await esp32Device!.discoverServices();
      for (var service in services) {
        service.characteristics.forEach((characteristic) async {
          if (characteristic.uuid.toString() == buzzerCharc) {
            List<int> command = [isOn ? 1 : 0];
            await characteristic.write(command);
            print('Buzzer is ${isOn ? 'on' : 'off'}');
          }
        });
      }
    }
  }

  void showSnackbar(String message) {
    Get.snackbar('Buzzer Activated', message);
  }

  void showSwitchToGPSPrompt() {
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

            Get.to(() => GoogleMapsScreen(
                  databaseReference: databaseReference,
                ));
          },
          child: const Text('Switch to GPS'),
        ),
      ],
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
                    Get.to(() =>
                        GoogleMapsScreen(databaseReference: databaseReference));
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
              )
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

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }
}
