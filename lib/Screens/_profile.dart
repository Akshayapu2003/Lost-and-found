import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:main/GetxControllers/controllers.dart';
import 'package:main/Screens/login.dart';
import 'package:main/constants/constants.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final UserController userController = Get.find<UserController>();

  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => SingleChildScrollView(
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
                Positioned(
                  top: 210,
                  left: 20,
                  child: GestureDetector(
                    onTap: () {
                      print('Tapped on profile picture');
                      userController.pickImage();
                    },
                    child: Obx(
                      () => CircleAvatar(
                        backgroundImage: userController.image.value != null
                            ? FileImage(userController.image.value!)
                            : const AssetImage('assets/images/logo.png')
                                as ImageProvider,
                        radius: 43,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 260,
                  left: 65,
                  child: IconButton(
                    onPressed: () {
                      print('Tapped on edit icon');
                      userController.pickImage();
                    },
                    icon: Container(
                      height: 29,
                      width: 29,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 22, 174, 147),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Color.fromARGB(255, 255, 255, 255),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 235,
                  left: 120,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          print('Tapped on name');
                          _nameController.text = userController.name.value;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              content: TextField(
                                controller: _nameController,
                                onChanged: (newValue) {
                                  userController.setName(newValue);
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Enter Name',
                                  hintStyle: TextStyle(color: Colors.white),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                  },
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    userController
                                        .setName(_nameController.text);
                                    Get.back();
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Obx(
                          () => Text(
                            userController.name.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: "Poppins",
                              fontSize: 23,
                              fontWeight: FontWeight.w500,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          print('Tapped on name edit icon');
                          _nameController.text = userController.name.value;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              content: TextField(
                                controller: _nameController,
                                onChanged: (newValue) {
                                  userController.setName(newValue);
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Enter Name',
                                  hintStyle: TextStyle(color: Colors.white),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                  },
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    userController
                                        .setName(_nameController.text);
                                    Get.back();
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  top: 300,
                  child: SizedBox(
                    child: ListView(
                      children: [
                        buildListTile(
                            'Phone', userController.phone.value, context),
                        buildListTile(
                            'Email', userController.email.value, context),
                        buildListTile('Feedback', "Give Feedback", context),
                        buildListTile('SignOut', "SignOut", context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildListTile(String title, String value, BuildContext context) {
    IconData iconData;
    Function()? onTap;
    switch (title.toLowerCase()) {
      case 'phone':
        iconData = Icons.call;
        onTap = () => _launchPhone(value);
        break;
      case 'email':
        iconData = Icons.email;
        onTap = () => _launchEmail(value);
        break;
      case 'signout':
        iconData = Icons.logout_outlined;
        onTap = () => logout(context);
        break;
      case 'feedback':
        iconData = Icons.feedback;
        onTap = () => _giveFeedback(context);
        break;
      default:
        iconData = Icons.info;
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: const Color.fromARGB(255, 30, 28, 28).withOpacity(0.3),
        child: ListTile(
          leading: Icon(
            iconData,
            color: Colors.white,
          ),
          title: Text(
            title.toLowerCase() != 'signout' &&
                    title.toLowerCase() != 'feedback'
                ? value
                : title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Enriqueta',
              fontSize: 14.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            if (onTap != null) {
              print('Tapped on $title');
              onTap();
            }
          },
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(LoginScreen());
      await saveUserDataToDatabase(
        name: userController.name.value,
        email: userController.email.value,
        phone: userController.phone.value,
      );
    } catch (e) {
      print('Error logging out: $e');
      showSnackBar(context, 'Error logging out: $e');
    }
  }

  void _launchPhone(String phoneNumber) async {
    print('Launching phone call to $phoneNumber');
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrlString(phoneUri.toString())) {
      await launchUrlString(phoneUri.toString());
    } else {
      print('Could not launch $phoneUri');
    }
  }

  void _launchEmail(String emailAddress) async {
    print('Launching email composer for $emailAddress');
    final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: emailAddress,
        queryParameters: {'subject': 'Subject', 'body': 'Body'});
    if (await canLaunchUrlString(emailLaunchUri.toString())) {
      await launchUrlString(emailLaunchUri.toString());
    } else {
      print('Could not launch $emailLaunchUri');
    }
  }

  Future<void> saveUserDataToDatabase({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      print('Saving user data to database');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await Firebase.initializeApp();
        final databaseReference = FirebaseDatabase.instance.ref();
        await databaseReference.child('users').child(user.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
        });
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<void> _giveFeedback(BuildContext context) async {
    String feedback = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDialogBackgroundColor,
        title:
            const Text('Give Feedback', style: TextStyle(color: Colors.white)),
        content: TextField(
          onChanged: (text) {
            feedback = text;
          },
          decoration: const InputDecoration(
            hintText: 'Enter your feedback here',
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print('Submitting feedback: $feedback');
              submitFeedback(feedback, context);
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> submitFeedback(String feedback, BuildContext context) async {
    try {
      print('Submitting feedback to database');
      final user = FirebaseAuth.instance.currentUser;
      final database = FirebaseDatabase.instance.ref();
      if (user != null) {
        await database.child('feedback').push().set({
          'userId': user.uid,
          'name': userController.name.value,
          'email': userController.email.value,
          'feedback': feedback,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        showSnackBar(
          context,
          'Thank you for your feedback!',
        );
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      Get.snackbar('Error', 'Failed to submit feedback: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: kSnackbarBackgroundColor,
          colorText: Colors.white);
    }
  }

  void showSnackBar(BuildContext context, String message) {
    print('Showing snackbar: $message');
    Get.snackbar(
      'Feedback',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: kSnackbarBackgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}
