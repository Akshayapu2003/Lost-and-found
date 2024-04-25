import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main/Screens/landing.dart';
import 'package:main/classes/auth_methods.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:main/firebase_options.dart';

class FirebaseAuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<FirebaseAuthMethods>(FirebaseAuthMethods(FirebaseAuth.instance));
    Get.put<UserController>(UserController());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'trAckit',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(color: Color.fromARGB(255, 0, 0, 0)),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
        ),
        snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color.fromARGB(255, 0, 0, 0),
            actionTextColor: Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: const LandingScreen(),
      initialBinding: FirebaseAuthBinding(),
    );
  }
}
