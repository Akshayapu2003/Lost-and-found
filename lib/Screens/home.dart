import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:main/Functions/show_dialog_signout.dart';
import 'package:main/GetxControllers/controllers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  final UserController userController = Get.find<UserController>();
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _updateUserLocation(Position position) {
    userController
        .setCurrentLocation(LatLng(position.latitude, position.longitude));
    updateCameraPosition(userController.currentPosition.value!);
  }

  void _getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final newPermission = await Geolocator.requestPermission();
      if (newPermission != LocationPermission.whileInUse &&
          newPermission != LocationPermission.always) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showErrorDialog(
          context,
          'Location permissions are permanently denied, we cannot request permissions.',
          'GPS is disabled');
      await Geolocator.openAppSettings();
      return;
    }

    try {
      Position positionLowAccuracy = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _updateUserLocation(positionLowAccuracy);

      Position positionHighAccuracy = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateUserLocation(positionHighAccuracy);
      _locationSubscription =
          Geolocator.getPositionStream().listen(_updateUserLocation);
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
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetLatLng =
        userController.currentPosition.value ?? const LatLng(10.1632, 76.6413);
    Future onPop() {
      return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Are you sure?'),
              content: const Text('Are you sure, You want to leave this page?'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Never-mind')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text('Leave'))
              ],
            );
          });
    }

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            return;
          }
          final bool shouldpop = await onPop() ?? false;
          if (context.mounted && shouldpop) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
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
            )));
  }
}
