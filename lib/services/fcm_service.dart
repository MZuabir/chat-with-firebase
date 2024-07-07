import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  CollectionReference fcmCollection =
      FirebaseFirestore.instance.collection('fcm_tokens');
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  getFcmToken() async => await messaging.getToken();

  addFcmToFirebase(String mail, String fcm) async {
    await fcmCollection.doc(mail).set({'fcm_token': fcm});
  }

  getFcmFromFirebase(String mail) async {
    var data = await fcmCollection.doc(mail).get();
    // log('this is fcm from firebase ${data['fcm_token']}');
    return data['fcm_token'];
  }
}
