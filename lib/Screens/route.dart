import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:main/Functions/snackbar.dart';
import 'package:main/constants/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class GoogleMapsScreen extends StatefulWidget {
  final DatabaseReference databaseReference;

  const GoogleMapsScreen({super.key, required this.databaseReference});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  LatLng? currentPosition;
  List<LatLng> coordinates = [];
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  Map<PolylineId, Polyline> polylines = {};

  double distance = 0.0;
  String estimatedTime = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp();
      await _getCurrentLocation();
      await getCoordinatesFromDatabase();
      final gcoordinates = await getPolyLinePoints();
      generatePolylineFromPoints(gcoordinates);
      calculateDistanceAndTime();
    } catch (e) {
      showSnackBar(context, 'Error initializing app: $e');
    }
  }

  void calculateDistanceAndTime() {
    if (currentPosition != null && coordinates.isNotEmpty) {
      setState(() {
        distance = Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          coordinates.last.latitude,
          coordinates.last.longitude,
        );
      });
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
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      showSnackBar(context, 'Error fetching current location: $e');
    }
  }

  Future<void> getCoordinatesFromDatabase() async {
    try {
      final event =
          await widget.databaseReference.child('gps_coordinates').once();
      final snapshot = event.snapshot;
      final values = snapshot.value as Map<dynamic, dynamic>?;
      if (values != null) {
        final coordinatesList = values.entries
            .map((entry) => LatLng(
                  entry.value['latitude'] as double,
                  entry.value['longitude'] as double,
                ))
            .toList();

        setState(() {
          coordinates = coordinatesList;
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error fetching coordinates: $e');
    }
  }

  Future<List<LatLng>> getPolyLinePoints() async {
    final polylinecoordinates = <LatLng>[];
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAPS_API_KEY,
      PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
      PointLatLng(coordinates.last.latitude, coordinates.last.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (final point in result.points) {
        polylinecoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      print(result.errorMessage);
    }
    return polylinecoordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylinecoordinates) async {
    const id = PolylineId("poly");
    final polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylinecoordinates,
      width: 10,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }

  Future<void> _cameraPosition(LatLng pos) async {
    final controller = await _mapController.future;
    if (currentPosition != null) {
      final newCameraPosition = CameraPosition(
        target: pos,
        zoom: 5,
      );
      await controller
          .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetLatLng = currentPosition ?? const LatLng(10.9035, 76.4352);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController.complete(controller);
              },
              initialCameraPosition: CameraPosition(
                target: targetLatLng,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('Current Location'),
                  icon: BitmapDescriptor.defaultMarker,
                  position: targetLatLng,
                ),
                if (coordinates.isNotEmpty)
                  Marker(
                    markerId: const MarkerId('Device Location'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: coordinates.last,
                  ),
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
          ),
          Container(
            color: Colors.black,
            height: 50,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'Distance to destination: ${(distance / 1000).toStringAsFixed(2)} km\n',
              style: const TextStyle(
                fontFamily: "Enriqueta",
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
