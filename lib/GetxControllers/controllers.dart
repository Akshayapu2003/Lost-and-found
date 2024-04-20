import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class UserController extends GetxController {
  RxString name = ''.obs;
  RxString email = ''.obs;
  RxString phone = ''.obs;
  Rx<File?> image = Rx<File?>(null);
  Rx<Position?> currentPosition = Rx<Position?>(null);

  RxString get gName => name;
  RxString get gemail => email;
  RxString get gPhone => phone;
  File? get gImage => image.value;
  Rx<Position?> get gcurrentPosition => currentPosition;

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

  void setCurrentLocation(Position value) {
    currentPosition.value = value;
    update();
  }
}
