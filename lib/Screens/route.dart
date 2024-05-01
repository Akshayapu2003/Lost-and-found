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
import 'package:main/Screens/landing.dart';
import 'package:main/constants/constants.dart';

class GoogleMapsScreen extends StatefulWidget {
  final DatabaseReference databaseReference;
  final String uuid;

  const GoogleMapsScreen(
      {Key? key, required this.databaseReference, required this.uuid})
      : super(key: key);

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
  final CoordinatesController _coordinatesController =
      Get.find<CoordinatesController>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _listenForLocationChanges();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp();
      await _getCurrentLocation();
      await _fetchCoordinatesFromFirebase();
      fetchPolylinePoints();
      calculateDistance();
      speakDistance();
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
        _coordinatesController.setCoordinates(coordinates);
      }
    } catch (e) {
      print('Error fetching coordinates from Firebase: $e');
    }
  }

  Future<void> fetchPolylinePoints() async {
    try {
      final polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_MAPS_API_KEY,
        PointLatLng(_userController.currentPosition.value!.latitude,
            _userController.currentPosition.value!.longitude),
        PointLatLng(_coordinatesController.coordinates.last.latitude,
            _coordinatesController.coordinates.last.longitude),
        travelMode: TravelMode.driving,
      );
      if (result.points.isNotEmpty) {
        setState(() {
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
        _coordinatesController.coordinates.isNotEmpty) {
      setState(() {
        _distance = Geolocator.distanceBetween(
          _userController.currentPosition.value!.latitude,
          _userController.currentPosition.value!.longitude,
          _coordinatesController.coordinates.last.latitude,
          _coordinatesController.coordinates.last.longitude,
        );
      });
    }
  }

  Future<void> speakDistance() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(
        "Distance to destination: ${(_distance / 1000).toStringAsFixed(2)} kilometers");
  }

  void _updateCameraPosition(LatLng position) async {
    final controller = await _mapController.future;
    if (_userController.currentPosition.value != null) {
      final newCameraPosition = CameraPosition(target: position, zoom: 15);
      await controller
          .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    }
  }

  Future<void> _listenForLocationChanges() async {
    try {
      await for (var location in Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10, // Adjust as needed
      ))) {
        _userController
            .setCurrentLocation(LatLng(location.latitude, location.longitude));
        _updateCameraPosition(_userController.currentPosition.value!);
        calculateDistance();
        speakDistance();
        setState(() {}); // Trigger UI update
      }
    } catch (e) {
      showSnackBar(context, 'Error listening for location changes: $e');
    }
  }

  void startScanAndNavigateToItemScreen() {
    FlutterBlue flutterBlue = FlutterBlue.instance;
    StreamSubscription<ScanResult>? scanSubscription;
    scanSubscription = flutterBlue.scan().listen((scanResult) {
      BluetoothDevice device = scanResult.device;
      if (device.name == 'ESP32_GPS_BLE') {
        Get.to(() => const ItemScreen());
        scanSubscription?.cancel();
      }
    });
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
                    if (_coordinatesController.coordinates.isNotEmpty)
                      Marker(
                          markerId: const MarkerId('Device Location'),
                          icon: BitmapDescriptor.defaultMarker,
                          position: _coordinatesController.coordinates.last),
                  },
                  polylines: _polylines,
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
