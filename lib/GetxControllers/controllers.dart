import 'dart:io';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class UserController extends GetxController {
  RxString name = ''.obs;
  RxString email = ''.obs;
  RxString phone = ''.obs;
  RxString pwd = ''.obs;

  Rx<File?> image = Rx<File?>(null);
  Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  RxBool startScanning = false.obs;
  RxString uuid = ''.obs;
  RxList<LatLng> coordinates = <LatLng>[].obs;

  RxString get gName => name;
  RxString get gemail => email;
  RxString get gPhone => phone;
  RxString get gpwd => pwd;

  File? get gImage => image.value;
  Rx<LatLng?> get gcurrentPosition => currentPosition;
  bool get gstartScanning => false;
  List<LatLng> get gCoordinates => coordinates.toList();

  void setName(String value) {
    name.value = value;
    update();
  }

  void setEmail(String value) {
    email.value = value;
    update();
  }

  void setPhone(String value) {
    phone.value = value;
    update();
  }

  void setPassword(String value) {
    pwd.value = value;
    update();
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      image.value = File(pickedFile.path);
    }
  }

  void setCurrentLocation(LatLng value) {
    currentPosition.value = value;
    update();
  }

  void setStartScanning(bool value) {
    startScanning.value = value;
  }

  void setUUID(String value) {
    uuid.value = value;
    update();
  }

  void setCoordinates(List<LatLng> newCoordinates) {
    coordinates.assignAll(newCoordinates);
    update();
  }
}
