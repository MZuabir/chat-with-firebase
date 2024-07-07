import 'package:chat_with_firebase/services/auth_service.dart';
import 'package:chat_with_firebase/views/login_screen.dart';
import 'package:chat_with_firebase/views/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController userNamecontroller = TextEditingController();
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
              const SizedBox(
                height: 50,
              ),
              LottieBuilder.asset('assets/lottieJson/back.json'),
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 70),
              const Text('Email'),
              TextField(
                controller: emailcontroller,
              ),
              const Text('User Name'),
              TextField(
                controller: userNamecontroller,
              ),
              const SizedBox(height: 20),
              const Text('Password'),
              TextField(
                controller: passwordcontroller,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 45,
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange),
                    onPressed: () async {
                      if (emailcontroller.text.trim().isEmpty ||
                          passwordcontroller.text.trim().isEmpty ||
                          userNamecontroller.text.trim().isEmpty) {
                        Fluttertoast.showToast(msg: 'Enter all fields carefully');
                      } else {
                        try {
                          await authService.signUpWithEmailAndPassword(
                              emailcontroller.text.trim(),
                              passwordcontroller.text.trim(),
                              userNamecontroller.text.trim());
                          await authService.signInWithEmailAndPassword(
                              emailcontroller.text.trim(),
                              passwordcontroller.text.trim());
                          // ignore: use_build_context_synchronously
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainScreen()),
                              (route) => false);
                        } catch (e) {
                          Fluttertoast.showToast(msg: e.toString());
                        }
                      }
                    },
                    child: const Text('Sign Up')),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()));
                      },
                      child: const Text(
                        'login',
                        style: TextStyle(color: Colors.orange),
                      ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
