import 'dart:developer';
import 'dart:typed_data';
import 'package:chat_with_firebase/models/group_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseService {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  CollectionReference userCollecRef =
      FirebaseFirestore.instance.collection('users');
  CollectionReference chatsRef= FirebaseFirestore.instance.collection('chat_place');
  CollectionReference groupsRef= FirebaseFirestore.instance.collection('groups');

  getAllUsers(String uid) {
    return userCollecRef.where('uid', isNotEqualTo: uid).snapshots();
  }


   getAllchats() async {
  log('all chat function called');
  QuerySnapshot data = await chatsRef.get();
  log(data.docs.length.toString());
  if (data.docs.isNotEmpty) {
    List<GroupModel> allChats = [];

    for (var element in data.docs) {
      Map<String, dynamic> jsonData = element.data() as Map<String, dynamic>;
      GroupModel modelData = GroupModel.fromJson(jsonData);
      allChats.add(modelData);
    }

    return allChats;
  }
}

Stream<List<GroupModel>> getAllGroupsAndChats(String currentUserId) {
  final groupsStream = groupsRef.snapshots();

  final chatStreamSender = chatsRef
      .where('senderId', isEqualTo: currentUserId)
      .snapshots();

  final chatStreamReceiver = chatsRef
      .where('receiverId', isEqualTo: currentUserId)
      .snapshots();

  final mergedChatStream = Rx.merge([chatStreamSender, chatStreamReceiver]);

  final mergedStream = Rx.combineLatest2(
    groupsStream,
    mergedChatStream,
    (QuerySnapshot groups, QuerySnapshot chats) {
      final List<GroupModel> allChats = [];

      for (var element in groups.docs) {
        final jsonData = element.data() as Map<String, dynamic>;
        final modelData = GroupModel.fromJson(jsonData);
        allChats.add(modelData);
      }

      for (var element in chats.docs) {
        final jsonData = element.data() as Map<String, dynamic>;
        final modelData = GroupModel.fromJson(jsonData);
        allChats.add(modelData);
      }

      return allChats;
    },
  );

  return mergedStream;
}











  uploadImage(Uint8List  image, String fileName) {
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = reference.putData(image);
    return uploadTask;
  }

  updateUserSingleField(String userId, Map<String,dynamic> fieldToUpdate) async {
    return userCollecRef.doc(userId).update(fieldToUpdate);
  }
}
