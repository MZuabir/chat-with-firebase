import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userName;
  final String uid;
  final String userMail;
  final bool isOnline;
  final List<dynamic> groups;
  final Timestamp? lastOnline;
  final String typingWith;

  UserModel(
      {required this.typingWith,
      this.lastOnline,
      required this.userName,
      required this.uid,
      required this.userMail,
      required this.groups,
      required this.isOnline});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        lastOnline: json['lastOnline'],
        userName: json['userName'] ?? '',
        typingWith: json['typingWith'] ?? '',
        uid: json['uid'] ?? '',
        groups: json['groups'] ?? [],
        userMail: json['userMail'] ?? '',
        isOnline: json['isOnline'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'lastOnline': lastOnline,
      'userName': userName,
      'typingWith': typingWith,
      'uid': uid,
      'userMail': userMail,
      'groups': groups,
      'isOnline': isOnline
    };
  }
}
