import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math.dart' as vector;

class IndoorPositioning extends StatefulWidget {
  const IndoorPositioning({super.key});

  @override
  _IndoorPositioningState createState() => _IndoorPositioningState();
}

class _IndoorPositioningState extends State<IndoorPositioning> {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;

  late StreamSubscription _accelerometerSubscription;
  late StreamSubscription _gyroscopeSubscription;
  late StreamSubscription _magnetometerSubscription;

  vector.Vector3 _accelerationVector = vector.Vector3.zero();
  vector.Vector3 _rotationVector = vector.Vector3.zero();
  vector.Vector3 _magneticFieldVector = vector.Vector3.zero();

  vector.Vector3 _deviceDirection = vector.Vector3.zero();

  @override
  void initState() {
    super.initState();
    _scanForDevices();
    _accelerometerSubscription =
        accelerometerEvents.listen(_handleAccelerometerEvent);
    _gyroscopeSubscription = gyroscopeEvents.listen(_handleGyroscopeEvent);
    _magnetometerSubscription =
        magnetometerEvents.listen(_handleMagnetometerEvent);
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    _magnetometerSubscription.cancel();
    super.dispose();
  }

  void _scanForDevices() {
    _flutterBlue.scan().listen((ScanResult scanResult) {
      if (scanResult.device.name == 'ESP32-BLE-Server') {
        updatePositionAndDirection();
      }
    });
  }

  void updatePositionAndDirection() {
    _updateDirection();
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    _accelerationVector = vector.Vector3(event.x, event.y, event.z);
    _updateDirection();
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    _rotationVector = vector.Vector3(event.x, event.y, event.z);
    _updateDirection();
  }

  void _handleMagnetometerEvent(MagnetometerEvent event) {
    _magneticFieldVector = vector.Vector3(event.x, event.y, event.z);
    _updateDirection();
  }

  void _updateDirection() {
    _accelerationVector = _lowPassFilter(_accelerationVector, 0.1);
    _rotationVector = _lowPassFilter(_rotationVector, 0.1);
    _magneticFieldVector = _lowPassFilter(_magneticFieldVector, 0.1);

    _accelerationVector.normalize();

    vector.Vector3 gravityVector = vector.Vector3(
      2 *
          (_accelerationVector.x * _accelerationVector.z -
              _accelerationVector.y),
      2 *
          (_accelerationVector.y * _accelerationVector.z +
              _accelerationVector.x),
      1 -
          2 *
              (_accelerationVector.x * _accelerationVector.x +
                  _accelerationVector.y * _accelerationVector.y),
    );

    vector.Vector3 bodyFrameVector =
        _accelerationVector.cross(gravityVector).normalized();

    vector.Vector3 rotationVector = _rotationVector * (0.5 * pi / 180);
    vector.Quaternion rotationQuaternion =
        vector.Quaternion.axisAngle(rotationVector, rotationVector.length);

    vector.Vector3 rotatedMagneticFieldVector =
        rotationQuaternion.rotated(_magneticFieldVector);

    _deviceDirection =
        bodyFrameVector.cross(rotatedMagneticFieldVector).normalized();
    if (mounted) {
      setState(() {});
    }
  }

  vector.Vector3 _lowPassFilter(vector.Vector3 input, double alpha) {
    vector.Vector3? output = _LowPassFilterCache.outputCache;
    if (output == null) {
      output = input;
    } else {
      vector.Vector3 scaledOutput = output * (1 - alpha);
      vector.Vector3 scaledInput = input * alpha;
      output = scaledOutput + scaledInput;
    }
    _LowPassFilterCache.outputCache = output;
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: atan2(-_deviceDirection.y, _deviceDirection.x),
      child: Container(
        width: 100,
        height: 100,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
        child: const Icon(Icons.arrow_forward, size: 90, color: Colors.white),
      ),
    );
  }
}

extension _LowPassFilterCache on vector.Vector3 {
  static vector.Vector3? outputCache;
}
