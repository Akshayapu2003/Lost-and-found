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
  late GoogleMapController mapController;
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userController.setCurrentLocation(position);
    } catch (e) {
      print('Error: $e');
      showErrorDialog(context, 'Error getting the current location.', 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
        body: userController.currentPosition.value != null
            ? GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    userController.currentPosition.value!.latitude,
                    userController.currentPosition.value!.longitude,
                  ),
                  zoom: 15.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('Current Location'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: LatLng(
                      userController.currentPosition.value!.latitude,
                      userController.currentPosition.value!.longitude,
                    ),
                  ),
                },
                myLocationEnabled: true,
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }
}
