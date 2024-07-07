import 'dart:developer';

import 'package:chat_with_firebase/models/notification_model.dart';
import 'package:chat_with_firebase/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationService notificationService = NotificationService();
  FirebaseAuth auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: const Text('Notifications'),
      ),
      body: StreamBuilder(
        stream: notificationService
            .getNotificationforNotPage(auth.currentUser!.email!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.none) {
            return const Center(child: Text('No new notifications'));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          List<NotificationModel> notificationList = [];
          var data = snapshot.data!.docs;
          for (var element in data) {
            notificationList.add(NotificationModel.fromJson(
                element.data() as Map<String, dynamic>));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: notificationList.length,
            itemBuilder: (context, index) {
              log('this is notificationid ${notificationList[index].notificationid}');
              return Card(
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textColor: Colors.white,iconColor: Colors.white,
                  tileColor: notificationList[index].isSeen
                      ? Colors.blueAccent.withOpacity(.5)
                      : Colors.orange,
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(auth.currentUser!.email)
                            .collection('all_notifications')
                            .doc(notificationList[index].notificationid)
                            .update({'isSeen': true});
                      },
                      icon: Icon(notificationList[index].isSeen
                          ? Icons.mark_as_unread
                          : Icons.markunread)),
                  title: Text(notificationList[index].notificationTitle),
                  subtitle: Text(
                      'Message: ${notificationList[index].notificationBody}'),
                  trailing: IconButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(auth.currentUser!.email)
                          .collection('all_notifications')
                          .doc(notificationList[index].notificationid)
                          .update({'isDeleted': true});
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
