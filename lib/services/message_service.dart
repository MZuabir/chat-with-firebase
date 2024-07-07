import 'dart:developer';

import 'package:chat_with_firebase/models/message_model.dart';
import 'package:chat_with_firebase/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/Material.dart';

class MessageService extends ChangeNotifier {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference chatPlaceCollectionref =
      FirebaseFirestore.instance.collection('chat_place');
  CollectionReference groupRefrence =
      FirebaseFirestore.instance.collection('groups');

  Future<void> sendMessage({
    required String receiverId,
    String? receivername,
    String? textMessage,
    String? imageLink,
    String? documentLink,
    String? lat,
    String? long,
    bool? isLocation,
    String? locationLink,
    String? fileName,
    String? locationScreenshot,
    String? receiverEmail,
    required bool isGroup,
  }) async {
    final String senderId = firebaseAuth.currentUser!.uid;
    final String senderEmail = firebaseAuth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();
    final messageToSend = Message(
        isDeleted: false,
        textMessage: textMessage ?? '',
        receiverId: receiverId,
        senderEmail: senderEmail,
        senderId: senderId,
        imageLink: imageLink ?? '',
        documentLink: documentLink ?? '',
        isLocation: isLocation ?? false,
        latitude: lat ?? '',
        longitude: long ?? '',
        locationLink: locationLink ?? '',
        timestamp: timestamp,
        locationScreenshot: locationScreenshot,
        receiverEmail: receiverEmail,
        fileName: fileName);
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatPlaceId = ids.join('-');
    try {
      log(chatPlaceId);
      DocumentReference messageRef = await chatPlaceCollectionref
          .doc(chatPlaceId)
          .collection('messages')
          .add(messageToSend.toMap());
      chatPlaceCollectionref.doc(chatPlaceId).set({
        'receiverEmail': receiverEmail,
        'isGroup': isGroup,
        'lastMessage': textMessage,
        'lastMessageSender': '',
        'senderId': senderId,
        'receiverId': receiverId,
        'senderEmail': senderEmail,
        'createdAt': timestamp,
      });

      await messageRef.update({'messageId': messageRef.id});
    } catch (e) {
      log(e.toString());
    }
  }

  Stream<QuerySnapshot> getMessages(String senderId, String receiverId) {
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomid = ids.join('-');
    var data = FirebaseFirestore.instance
        .collection('chat_place')
        .doc(chatRoomid)
        .collection('messages')
        .where('isDeleted', isEqualTo: false)
        .orderBy('timeStamp', descending: true)
        .snapshots();

    return data;
  }

  deleteMessage(
      String senderId, String receiverId, List<String> messageId) async {
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomid = ids.join('-');
    for (int i = 0; i < messageId.length; i++) {
      log('is deleted true of doc ${messageId[i]}');
      await chatPlaceCollectionref
          .doc(chatRoomid)
          .collection('messages')
          .doc(messageId[i])
          .update({'isDeleted': true});
    }
  }

  Future<List<String>> getusermails(List<dynamic> ids) async {
    List<String> emails = [];
    List<UserModel> users = [];
    for (int i = 0; i < ids.length; i++) {
      var data = await firestore.collection('users').doc(ids[i]).get();
      users.add(UserModel.fromJson(data.data()!));
    }
    for (int i = 0; i < users.length; i++) {
      emails.add(users[i].userMail);
    }
    log(users.toString());
    return emails;
  }

  Future<List<String>> getUsersFcm(List<String> mails) async {
    List<String> fcms = [];
    for (int i = 0; i < mails.length; i++) {
      // log(mails[i].runtimeType.toString() + " mail: " + mails[i]);

      if (!(mails[i] == FirebaseAuth.instance.currentUser!.email)) {
        var data = await firestore.collection('fcm_tokens').doc(mails[i]).get();
        fcms.add(data.data()!['fcm_token']);
      }
    }
    log(fcms.toString());
    return fcms;
  }

  deleteMessageFromGroup(
      String senderId, String groupId, List<String> messageIds) async {
    for (int i = 0; i < messageIds.length; i++) {
      await groupRefrence
          .doc(groupId)
          .collection('messages')
          .doc(messageIds[i])
          .update({'isDeleted': true});
    }
  }
}
