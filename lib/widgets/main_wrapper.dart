import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:main/Screens/login.dart';
import 'package:main/widgets/widget_tree.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text("Something went wrong");
        } else if (snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WidgetTree()),
              );
            },
          );
          return Container();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
