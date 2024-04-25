import 'dart:io';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class UserController extends GetxController {
  RxString name = ''.obs;
  RxString email = ''.obs;
  RxString phone = ''.obs;
  Rx<File?> image = Rx<File?>(null);
  Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  RxBool isOnItemScreen = false.obs;
  RxString uuid = ''.obs;

  RxString get gName => name;
  RxString get gemail => email;
  RxString get gPhone => phone;
  File? get gImage => image.value;
  Rx<LatLng?> get gcurrentPosition => currentPosition;
  bool get gisOnItemScreen => true;

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

  void setIsOnItemScreen(bool value) {
    isOnItemScreen.value = value;
  }

  void setUUID(String value) {
    uuid.value = value;
    update();
  }
}
