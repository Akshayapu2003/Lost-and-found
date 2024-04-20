import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main/Functions/snackbar.dart';
import 'package:main/Screens/signup.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/widgets/widget_tree.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final UserController userController = Get.put(UserController());

    Future<void> loginUser(BuildContext context) async {
      try {
        final authMethods = FirebaseAuth.instance;
        final login = await authMethods.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        if (login != null) {
          Get.offAll(() => const WidgetTree());
          await Firebase.initializeApp();
          final databaseReference = FirebaseDatabase.instance.ref();
          final userSnapshot = await databaseReference
              .child('users')
              .child(login.user!.uid)
              .once();
          final userData =
              userSnapshot.snapshot.value as Map<dynamic, dynamic>?;
          if (userData != null) {
            final String name = userData['name'];
            final String email = userData['email'];
            final String phone = userData['phone'];

            userController.setName(name);
            userController.setPhone(phone);
            userController.setEmail(email);
          }
        } else {
          showSnackBar(context, 'Sign-up failed. Please try again.');
        }
      } catch (e) {
        print('Error logging in: $e');
        showSnackBar(context, 'Error');
      }
    }

    Future<void> resetPassword(String email) async {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        showSnackBar(context, "Password reset email sent to $email");
      } catch (e) {
        showSnackBar(context, "Failed to send password reset email: $e");
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Image.asset(
                  'assets/images/landing.jpeg',
                  fit: BoxFit.none,
                ),
              ),
              Positioned(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 439),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(17, 17, 17, 0),
                        Color(0xFF000000),
                      ],
                      stops: [0, 0.7969],
                    ),
                  ),
                ),
              ),
              Positioned(
                child: Container(
                  margin: const EdgeInsets.only(top: 313),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.fromRGBO(17, 17, 17, 0),
                        Color.fromARGB(255, 0, 0, 0),
                      ],
                      stops: [0, 0.0004],
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 300,
                left: 30,
                child: Text(
                  "Welcome back",
                  style: TextStyle(
                    fontFamily: "Enriqueta",
                    fontSize: 31,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              Positioned(
                top: 370,
                left: 30,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 60,
                  child: TextFormField(
                    controller: emailController,
                    style: const TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 255, 255, 255)),
                    decoration: InputDecoration(
                      hintText: "enter your email",
                      hintStyle: TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 450,
                left: 30,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 60,
                  child: TextFormField(
                    controller: passwordController,
                    style: const TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 255, 255, 255)),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "enter your password",
                      hintStyle: TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 510,
                right: 20,
                child: TextButton(
                  onPressed: () {
                    resetPassword(emailController.text);
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Enriqueta',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 160,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: () {
                    loginUser(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 10),
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  child: const Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Enriqueta',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 110,
                left: 66,
                right: 66,
                child: Row(
                  children: [
                    const Text(
                      "Don't have an Account?",
                      style: TextStyle(
                        fontFamily: 'Enriqueta',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.to(
                          () => SignUpScreen(),
                        );
                      },
                      child: const Text(
                        "SignUp",
                        style: TextStyle(
                          fontFamily: 'Enriqueta',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 30, 185, 84),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
