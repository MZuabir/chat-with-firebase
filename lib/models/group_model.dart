import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String? groupName;
  final String? groupAdmin;
  final Timestamp? createdAt;
  final List<dynamic>? members;
  final String? groupId;
  final String lastMessage;
  final String lastMessageSender;
  final String? senderId;
  final String? receiverId;
  final bool isGroup;
  final String? senderEmail;
  final String? receiverEmail;
  

  GroupModel(
      {
        this.senderEmail,
        this.receiverEmail,
      this.senderId, this.receiverId,   
       this.groupName,
       this.groupAdmin,
       this.createdAt,
       this.members,
       this.groupId,
       required this.isGroup,
      required this.lastMessage,
      required this.lastMessageSender});

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      senderEmail:json['senderEmail']??'',
      receiverEmail: json['receiverEmail'],
      isGroup: json['isGroup'],
      senderId: json['senderId']??'',
      receiverId: json['receiverId']??'',
        groupName: json['groupName']??'',
        groupAdmin: json['groupAdmin']??'',
        createdAt: json['createdAt'],
        members: json['members']??[],
        groupId: json['groupId']??'',
        lastMessage: json['lastMessage']??'',
        lastMessageSender: json['lastMessageSender']??'');
  }
  Map<String, dynamic> toJson() {
    return {
      'receiverEmail':receiverEmail,
      'senderEmail':senderEmail,
      'isGroup':isGroup,
      'groupName': groupName,
      'groupAdmin': groupAdmin,
      'createdAt': createdAt,
      'members': members,
      'groupId': groupId,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender
    };
  }
}
