

class NotificationModel {
  final String notificationTitle;
  final String notificationBody;
  final bool isSeen;
  final bool isDeleted;
  final String userId;
  final String userMail;
  final String? notificationid;

  NotificationModel(
      {required this.isSeen,
      required this.userId,
      required this.userMail,
      required this.isDeleted,
      required this.notificationTitle,
      this.notificationid,
      required this.notificationBody});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      userId: json['userId']??'',
      notificationid: json['notificationid']??'',
      userMail: json['userMail']??'',
        isSeen: json['isSeen'] ?? false,
        isDeleted: json['isDeleted'] ?? false,
        notificationTitle: json['notificationTitle'] ?? '',
        notificationBody: json['notificationBody']);
  }

  Map<String,dynamic> toJson(){
    return {
      'notificationid':notificationid,
      'userId':userId,
      'userMail':userMail,
      'isSeen':isSeen,
      'isDeleted':isDeleted,
      'notificationTitle':notificationTitle,
      'notificationBody':notificationBody,
    };
  }
}
