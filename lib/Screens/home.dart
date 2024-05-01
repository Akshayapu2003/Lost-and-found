import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:main/Functions/show_dialog_signout.dart';
import 'package:main/GetxControllers/controllers.dart';

void main() => runApp(const HomeScreen());

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showErrorDialog(context,
          'Location services are disabled. Please enable them.', 'Enable GPS');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showErrorDialog(
            context, 'Location permissions are denied.', 'GPS is disabled');
        return;
      }
    }

    try {
      Position positionLowAccuracy = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      userController.setCurrentLocation(
          LatLng(positionLowAccuracy.latitude, positionLowAccuracy.longitude));

      updateCameraPosition(userController.currentPosition.value!);

      Position positionHighAccuracy = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userController.setCurrentLocation(LatLng(
          positionHighAccuracy.latitude, positionHighAccuracy.longitude));
      updateCameraPosition(userController.currentPosition.value!);
    } catch (e) {
      print('Error: $e');
      showErrorDialog(context, 'Error getting the current location.', 'Error');
    }
  }

  void updateCameraPosition(LatLng position) async {
    final controller = await mapController.future;
    if (userController.currentPosition.value != null) {
      final newCameraPosition = CameraPosition(
        target: position,
        zoom: 15,
      );
      await controller
          .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetLatLng =
        userController.currentPosition.value ?? const LatLng(10.1632, 76.6413);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Current Location',
            style: TextStyle(
              fontFamily: "Enriqueta",
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          elevation: 2,
        ),
        body: GoogleMap(
          onMapCreated: (controller) {
            mapController.complete(controller);
          },
          initialCameraPosition: CameraPosition(
            target: targetLatLng,
            zoom: 5.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('Current Location'),
              icon: BitmapDescriptor.defaultMarker,
              position: targetLatLng,
            ),
          },
          myLocationEnabled: true,
        ));
  }
}
