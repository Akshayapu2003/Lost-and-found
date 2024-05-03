import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:main/Functions/snackbar.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/Screens/items.dart';
import 'package:main/constants/constants.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as maps_toolkit;

class GoogleMapsScreen extends StatefulWidget {
  final DatabaseReference databaseReference;
  final String uuid;

  const GoogleMapsScreen(
      {super.key, required this.databaseReference, required this.uuid});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final Set<Polyline> _polylines = {};
  double _distance = 0.0;
  final UserController _userController = Get.find<UserController>();
  final FlutterTts _flutterTts = FlutterTts();
  final UserController userController = Get.find<UserController>();
  bool _isLoading = true;

  StreamSubscription<ScanResult>? _scanSubscription;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<List<LatLng>>? _databaseSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _startListening();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp();
      await _getCurrentLocation();
      await _fetchCoordinatesFromFirebase();
    } catch (e) {
      showSnackBar(context, 'Error initializing app: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission != LocationPermission.whileInUse &&
            newPermission != LocationPermission.always) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      _userController
          .setCurrentLocation(LatLng(position.latitude, position.longitude));
      _updateCameraPosition(_userController.currentPosition.value!);
    } catch (e) {
      showSnackBar(context, 'Error fetching current location: $e');
    }
  }

  Future<void> _fetchCoordinatesFromFirebase() async {
    try {
      final coordinatesSnapshot = await widget.databaseReference
          .child(widget.uuid)
          .child('gps_coordinates')
          .once();
      final coordinatesData =
          coordinatesSnapshot.snapshot.value as Map<dynamic, dynamic>?;
      if (coordinatesData != null) {
        final coordinates = coordinatesData.entries
            .map((entry) => LatLng(entry.value['latitude'] as double,
                entry.value['longitude'] as double))
            .toList();
        userController.setCoordinates(coordinates);
      }
    } catch (e) {
      print('Error fetching coordinates from Firebase: $e');
    }
  }

  Stream<List<LatLng>> _coordinatesStream() {
    return widget.databaseReference
        .child(widget.uuid)
        .child('gps_coordinates')
        .onValue
        .map((event) {
      final coordinatesData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (coordinatesData != null) {
        return coordinatesData.entries
            .map((entry) => LatLng(entry.value['latitude'] as double,
                entry.value['longitude'] as double))
            .toList();
      } else {
        return [];
      }
    });
  }

  Future<void> fetchPolylinePoints() async {
    try {
      final polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_MAPS_API_KEY,
        PointLatLng(_userController.currentPosition.value!.latitude,
            _userController.currentPosition.value!.longitude),
        PointLatLng(userController.coordinates.last.latitude,
            userController.coordinates.last.longitude),
        travelMode: TravelMode.driving,
      );
      if (result.points.isNotEmpty) {
        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId("poly"),
            color: Colors.blue,
            points: result.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(),
            width: 10,
          ));
          _isLoading = false;
        });
      } else {
        throw 'No polyline points found';
      }
    } catch (e) {
      print('Error fetching polyline points: $e');
    }
  }

  void calculateDistance() {
    if (_userController.currentPosition.value != null &&
        userController.coordinates.isNotEmpty) {
      setState(() {
        _distance = Geolocator.distanceBetween(
          _userController.currentPosition.value!.latitude,
          _userController.currentPosition.value!.longitude,
          userController.coordinates.last.latitude,
          userController.coordinates.last.longitude,
        );
      });
    }
  }

  Future<void> speakInstructions() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1);
    await _flutterTts.setSpeechRate(0.5);

    if (_distance > 0) {
      await _flutterTts.speak(
          "Distance to destination: ${(_distance / 1000).toStringAsFixed(2)} kilometers");
    }

    // Get the polyline points
    List<LatLng> polylinePoints =
        _polylines.isNotEmpty ? _polylines.first.points : [];

    // Find the closest point on the polyline to the user's current location
    LatLng userLocation = _userController.currentPosition.value!;
    int closestPointIndex =
        _findClosestPointOnPolyline(userLocation, polylinePoints);

    // Generate navigation instructions based on user's position and next few points
    String instructions = _generateNavigationInstructions(
        userLocation, polylinePoints, closestPointIndex);

    // Speak the instructions
    await _flutterTts.speak(instructions);
  }

  int _findClosestPointOnPolyline(
      LatLng userLocation, List<LatLng> polylinePoints) {
    double minDistance = double.infinity;
    int closestPointIndex = 0;

    for (int i = 0; i < polylinePoints.length; i++) {
      double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          polylinePoints[i].latitude,
          polylinePoints[i].longitude);
      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }

    return closestPointIndex;
  }

  String _generateNavigationInstructions(
      LatLng userLocation, List<LatLng> polylinePoints, int closestPointIndex) {
// Check if closestPointIndex is not the last point in the polyline
    if (closestPointIndex < polylinePoints.length - 1) {
      LatLng nextPoint = polylinePoints[closestPointIndex + 1];
      num bearing = maps_toolkit.SphericalUtil.computeHeading(
          userLocation as maps_toolkit.LatLng,
          nextPoint as maps_toolkit.LatLng);
      num distance = maps_toolkit.SphericalUtil.computeDistanceBetween(
          userLocation as maps_toolkit.LatLng,
          nextPoint as maps_toolkit.LatLng);

      if (bearing >= 337.5 || bearing < 22.5) {
        return "Continue straight for ${distance.toStringAsFixed(0)} meters";
      } else if (bearing >= 22.5 && bearing < 67.5) {
        return "Turn right in ${distance.toStringAsFixed(0)} meters";
      } else if (bearing >= 67.5 && bearing < 112.5) {
        return "Turn right in ${distance.toStringAsFixed(0)} meters";
      } else if (bearing >= 112.5 && bearing < 157.5) {
        return "Turn right in ${distance.toStringAsFixed(0)} meters";
      } else if (bearing >= 157.5 && bearing < 202.5) {
        return "Turn around in ${distance.toStringAsFixed(0)} meters";
      } else if (bearing >= 202.5 && bearing < 247.5) {
        return "Turn left in ${distance.toStringAsFixed(0)} meters";
      } else if (bearing >= 247.5 && bearing < 292.5) {
        return "Turn left in ${distance.toStringAsFixed(0)} meters";
      } else {
        return "Turn left in ${distance.toStringAsFixed(0)} meters";
      }
    } else {
      return "You have reached your destination";
    }
  }

  void _updateCameraPosition(LatLng position) async {
    final controller = await _mapController.future;
    if (_userController.currentPosition.value != null) {
      final newCameraPosition = CameraPosition(target: position, zoom: 15);
      await controller
          .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    }
  }

  void _startListening() {
    _scanSubscription = FlutterBlue.instance.scan().listen((scanResult) {
      BluetoothDevice device = scanResult.device;
      if (device.name == 'ESP32-BLE-Server') {
        Get.to(() => const ItemScreen());
// You can add additional logic here if needed
      }
    });
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
      ),
    ).listen((position) {
      _userController
          .setCurrentLocation(LatLng(position.latitude, position.longitude));
      _updateCameraPosition(_userController.currentPosition.value!);
      calculateDistance();
      speakInstructions();
      setState(() {});
    });

    _databaseSubscription = _coordinatesStream().listen((coordinates) {
      userController.setCoordinates(coordinates);
      fetchPolylinePoints();
      calculateDistance();
      speakInstructions();
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _locationSubscription?.cancel();
    _databaseSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetLatLng =
        _userController.currentPosition.value ?? const LatLng(10.1632, 76.6413);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_isLoading)
                  const Center(
                    child: Text(
                      "Finding Best Route",
                      style: TextStyle(
                        color: Colors.black54,
                        fontFamily: "Enriqueta",
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController.complete(controller);
                  },
                  initialCameraPosition:
                      CameraPosition(target: targetLatLng, zoom: 5),
                  markers: {
                    Marker(
                        markerId: const MarkerId('Current Location'),
                        icon: BitmapDescriptor.defaultMarker,
                        position: targetLatLng),
                    if (userController.coordinates.isNotEmpty)
                      Marker(
                          markerId: const MarkerId('Device Location'),
                          icon: BitmapDescriptor.defaultMarker,
                          position: userController.coordinates.last),
                  },
                  polylines: _polylines,
                  myLocationEnabled: true,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.black,
            height: 60,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                'Distance to destination: ${(_distance / 1000).toStringAsFixed(2)} km\n',
                style: const TextStyle(
                  fontFamily: "Enriqueta",
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
