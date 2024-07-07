import 'dart:developer';

import 'package:chat_with_firebase/models/user_model.dart';
import 'package:chat_with_firebase/services/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthService extends ChangeNotifier {
  FcmService fcmService = FcmService();
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  CollectionReference userCollecRef =
      FirebaseFirestore.instance.collection('users');

  //login with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      DateTime time = DateTime.now();
      String token = await fcmService.getFcmToken();
      log(token.toString());
      firebaseFirestore.collection('users').doc(userCredential.user!.uid).set(
          {'uid': userCredential.user!.uid, 'email': email, 'lastOnline': time},
          SetOptions(merge: true));
      try {
        await fcmService.addFcmToFirebase(email, token);
      } catch (e) {
        log(e.toString());
      }
      return userCredential;
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      throw Exception(e);
      // throw Exception(e);
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      String token = await fcmService.getFcmToken();
      firebaseFirestore.collection('users').doc(userCredential.user!.uid).set(
            UserModel(
                    typingWith: '',
                    isOnline: false,
                    userName: username,
                    userMail: email,
                    groups: [],
                    uid: userCredential.user!.uid)
                .toJson(),
          );
      try {
        await fcmService.addFcmToFirebase(email, token);
      } catch (e) {
        log(e.toString());
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      throw Exception(e);
    }
  }

  void userSignOut() async {
    await firebaseAuth.signOut().then((value) {
      Fluttertoast.showToast(msg: 'Signed out');
    });
  }

  Stream<DocumentSnapshot> checkUserOnline(String userId) {
    return userCollecRef.doc(userId).snapshots();
  }
}
