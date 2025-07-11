import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main/Screens/login.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Positioned(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              top: 0,
              left: 0,
              child: Image.asset(
                'assets/images/landing.jpeg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              child: Container(
                width: 430,
                height: 912,
                margin: const EdgeInsets.only(top: 420),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xFF111111),
                    ],
                    stops: [0, 0.7969],
                  ),
                ),
              ),
            ),
            Positioned(
              width: 55,
              height: 55,
              top: 255,
              left: 30,
              child: Image.asset("assets/images/design.png"),
            ),
            const Positioned(
              top: 420,
              left: 20,
              child: Text(
                "Empowering",
                style: TextStyle(
                  fontFamily: 'Enriqueta',
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            const Positioned(
              top: 465,
              left: 20,
              child: Text(
                "Seamless ",
                style: TextStyle(
                  fontFamily: 'Enriqueta',
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            const Positioned(
              top: 510,
              left: 20,
              child: Text(
                "Retrieval",
                style: TextStyle(
                  fontFamily: 'Enriqueta',
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            const Positioned(
              top: 570,
              left: 20,
              child: SelectableText(
                "Unveiling an IoT-driven ",
                style: TextStyle(
                  fontFamily: 'Enriqueta',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color.fromARGB(255, 201, 187, 187),
                ),
              ),
            ),
            const Positioned(
              top: 595,
              left: 20,
              child: Text(
                "Lost and Found System for efficient",
                style: TextStyle(
                  fontFamily: 'Enriqueta',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color.fromARGB(255, 201, 187, 187),
                ),
              ),
            ),
            const Positioned(
              top: 620,
              left: 20,
              child: Text(
                "Item tracking and recovery.",
                style: TextStyle(
                  fontFamily: 'Enriqueta',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color.fromARGB(255, 201, 187, 187),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () async {
                  Get.to(() => LoginScreen());
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 10),
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                ),
                child: const Text(
                  'Track it',
                  style: TextStyle(
                    fontFamily: 'Enriqueta',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 32, 32, 32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
