import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main/Functions/snackbar.dart';
import 'package:main/Screens/login.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../GetxControllers/controllers.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final UserController userController = Get.find<UserController>();

  final TextEditingController _textFieldController = TextEditingController();

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
                  child: CircleAvatar(
                    backgroundImage: userController.image.value != null
                        ? FileImage(userController.image.value!)
                        : const AssetImage('assets/images/logo.png')
                            as ImageProvider,
                    radius: 43,
                  ),
                ),
                Positioned(
                  top: 260,
                  left: 65,
                  child: IconButton(
                    onPressed: () {
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
                  child: Wrap(
                    children: [
                      Text(
                        "${userController.name}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: "Poppins",
                            fontSize: 23,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 239,
                  right: 32,
                  child: IconButton(
                    onPressed: () {
                      _textFieldController.text = "${userController.name}";
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          content: TextField(
                            controller: _textFieldController,
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
                                Get.back();
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.height * 0.03,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).size.height * 0.33 -
                        70,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 300),
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
    _textFieldController.text = "";
    if (title.toLowerCase() != 'signout' && title.toLowerCase() != 'feedback') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: const Color.fromARGB(255, 42, 39, 39).withOpacity(0.3),
          child: ListTile(
            leading: Icon(
              iconData,
              color: Colors.white,
            ),
            title: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Enriqueta',
                fontSize: 14.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onTap,
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    content: TextField(
                      controller: _textFieldController,
                      onChanged: (newValue) {
                        value = newValue;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter new $title',
                        hintStyle: const TextStyle(color: Colors.white),
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
                          switch (title.toLowerCase()) {
                            case 'phone':
                              userController.setPhone(value);
                              break;
                            case 'email':
                              userController.setEmail(value);
                              break;
                            default:
                              break;
                          }
                          Get.back();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: const Color.fromARGB(255, 42, 39, 39).withOpacity(0.3),
          child: ListTile(
            leading: Icon(
              iconData,
              color: Colors.white,
            ),
            title: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Enriqueta',
                fontSize: 14.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onTap,
          ),
        ),
      );
    }
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
      showSnackBar(context, 'Error logging out: $e');
    }
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrlString(phoneUri.toString())) {
      await launchUrlString(phoneUri.toString());
    } else {
      print('Could not launch $phoneUri');
    }
  }

  void _launchEmail(String emailAddress) async {
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
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: const Text('Give Feedback'),
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
              _sendFeedbackByEmail(feedback, context);
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedbackByEmail(
      String feedback, BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'akshaya4703@gmail.com',
      queryParameters: {'subject': 'Feedback', 'body': feedback},
    );

    try {
      await launchUrlString(emailUri.toString());
      showSnackBar(
        context,
        'Feedback sent successfully!',
      );
    } catch (e) {
      print('Error sending feedback: $e');

      showSnackBar(
        context,
        'Failed to send feedback. Please try again later.',
      );
    }
  }
}
