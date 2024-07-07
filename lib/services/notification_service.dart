
import 'package:chat_with_firebase/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  uploadNotificationaToFirebase(String userEmail, String notificationTitle,
      String notificationBody) async {
    DocumentReference notRef= await firestore
        .collection('notifications')
        .doc(userEmail)
        .collection('all_notifications')
        .add(NotificationModel(
                isSeen: false,
                userId: auth.currentUser!.uid,
                userMail: userEmail,
                isDeleted: false,
                notificationTitle: notificationTitle,
                notificationBody: notificationBody)
            .toJson());
      await notRef.update({
        'notificationid':notRef.id
      });
  }

  Stream<QuerySnapshot> getNotifications(String userMail) {
    return firestore
        .collection('notifications')
        .doc(userMail)
        .collection('all_notifications')
        .where('isSeen', isEqualTo: false)
        .where('isDeleted', isEqualTo: false)
        .snapshots();
  }
  Stream<QuerySnapshot> getNotificationforNotPage(String userMail) {
    return firestore
        .collection('notifications')
        .doc(userMail)
        .collection('all_notifications')
        .where('isDeleted', isEqualTo: false)
        .snapshots();
  }
}
