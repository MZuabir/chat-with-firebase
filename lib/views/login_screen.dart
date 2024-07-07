import 'package:chat_with_firebase/services/auth_service.dart';
import 'package:chat_with_firebase/views/main_screen.dart';
import 'package:chat_with_firebase/views/sign_up_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  AuthService authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30,),
              Container(
                child: Lottie.asset('assets/lottieJson/spiritual_home.json'),),
              const Text(
                'LogIn to Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 70),
              const Text('Email'),
              TextFormField(
                controller: emailcontroller..text = "zubair@gmail.com",
              ),
              const SizedBox(height: 20),
              const Text('Password'),
              TextFormField(
                controller: passwordcontroller..text = '12345678',
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity,
              height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.white,backgroundColor: Colors.orange),
                    onPressed: () {
                      if (emailcontroller.text.trim().isEmpty ||
                          passwordcontroller.text.trim().isEmpty) {
                        Fluttertoast.showToast(msg: 'Enter all fields carefully');
                      } else {
                        try {
                          authService
                              .signInWithEmailAndPassword(
                                  emailcontroller.text.trim(),
                                  passwordcontroller.text.trim())
                              .then((value) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MainScreen()));
                          });
                        } on FirebaseException catch (e) {
                          Fluttertoast.showToast(msg: e.toString());
                        }
                      }
                    },
                    child: const Text('Login')),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpScreen()));
                      },
                      child: const Text('Sign up',style: TextStyle(color: Colors.orange),))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
