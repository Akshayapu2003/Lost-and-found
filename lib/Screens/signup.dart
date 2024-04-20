import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main/Functions/snackbar.dart';
import 'package:main/classes/auth_methods.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/widgets/widget_tree.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final UserController userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    Future<void> saveUserDataToDatabase({
      required String name,
      required String email,
      required String phone,
    }) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DatabaseReference reference =
              FirebaseDatabase.instance.ref().child('users').child(user.uid);

          // Save user data to the database
          await reference.set(
            {
              'name': name,
              'email': email,
              'phone': phone,
            },
          );
        }
      } catch (e) {
        showSnackBar(context, 'Error saving user data: $e');
      }
    }

    Future<void> checkSignUp(BuildContext context) async {
      if (_passwordController.text == confirmPasswordController.text) {
        final result =
            await FirebaseAuthMethods(FirebaseAuth.instance).signUpWithEmail(
          email: emailController.text,
          password: _passwordController.text,
          context: context,
        );
        if (result) {
          userController.setName(nameController.text);
          userController.setPhone(phoneController.text);
          userController.setEmail(emailController.text);

          await saveUserDataToDatabase(
            name: userController.name.value,
            email: userController.email.value,
            phone: userController.phone.value,
          );
          Get.offAll(
            () => const WidgetTree(),
          );
        } else {
          showSnackBar(context, 'Sign-up failed. Please try again.');
        }
      } else {
        showSnackBar(context, 'Passwords do not match');
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
                top: 280,
                left: 30,
                child: Text(
                  "Create your Account",
                  style: TextStyle(
                    fontFamily: "Enriqueta",
                    fontSize: 31,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              Positioned(
                top: 345,
                left: 30,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 60,
                  child: TextFormField(
                    controller: nameController,
                    style: const TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 255, 255, 255)),
                    decoration: InputDecoration(
                      hintText: "enter your name",
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
                top: 415,
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
                top: 485,
                left: 30,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 60,
                  child: TextFormField(
                    controller: phoneController,
                    style: const TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 255, 255, 255)),
                    decoration: InputDecoration(
                      hintText: "+91",
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
                top: 555,
                left: 30,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 60,
                  child: TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(
                      fontFamily: "Enriqueta",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
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
                top: 625,
                left: 30,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 60,
                  child: TextFormField(
                    controller: confirmPasswordController,
                    style: const TextStyle(
                        fontFamily: "Enriqueta",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 255, 255, 255)),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Confirm Password",
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
                top: 720,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: () async {
                    await checkSignUp(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 10),
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  child: const Center(
                    child: Text(
                      'SignUp',
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
            ],
          ),
        ),
      ),
    );
  }
}
