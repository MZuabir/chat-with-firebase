import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? messageId;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String textMessage;
  final String imageLink;
  final String documentLink;
  final Timestamp timestamp;
  final bool? isDeleted;
  final bool isLocation;
  final String latitude;
  final String longitude;
  final String? locationLink;
  final String? fileName;
  final String? locationScreenshot;
  
  final String? receiverEmail;
  
  Message(
      {required this.isLocation,
      required this.latitude,
      required this.longitude,
      this.locationScreenshot,
      this.locationLink,
      this.messageId,
      this.fileName,
      this.receiverEmail,
      
      this.isDeleted,
      required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.timestamp,
      required this.textMessage,
      required this.documentLink,
      required this.imageLink});

  Map<String, dynamic> toMap() {
    return {
      'receiverEmail':receiverEmail,
     
      'locationScreenshot':locationScreenshot,
      'isLocation': isLocation,
      'locationLink': locationLink,
      'fileName': fileName,
      'latitude': latitude,
      'longitude': longitude,
      'messageId': messageId,
      'isDeleted': isDeleted,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'textMessage': textMessage,
      'documentLink': documentLink,
      'imageLink': imageLink,
      'timeStamp': timestamp
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      receiverEmail: json['receiverEmail']??'',
      locationScreenshot: json['locationScreenshot']??'',
      locationLink: json['locationLink'] ?? '',
      isLocation: json['isLocation'] ?? false,
      latitude: json['latitude'] ?? '',
      fileName: json['fileName'] ?? '',
      longitude: json['longitude'] ?? '',
      messageId: json['messageId'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      senderId: json['senderId'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      receiverId: json['receiverId'] ?? '',
      textMessage: json['textMessage'] ?? '',
      documentLink: json['documentLink'] ?? '',
      imageLink: json['imageLink'] ?? '',
      timestamp: json['timeStamp'],
    );
  }
}
