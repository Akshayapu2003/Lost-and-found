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
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(color: Color.fromARGB(255, 0, 0, 0)),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch:
              createMaterialColor(const Color.fromARGB(255, 29, 57, 118)),
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

  // Function to create a MaterialColor from a Color
  MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    final Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
