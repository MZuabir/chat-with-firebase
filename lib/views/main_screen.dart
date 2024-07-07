import 'dart:convert';
import 'dart:developer';
import 'package:chat_with_firebase/main.dart';
import 'package:chat_with_firebase/models/group_model.dart';
import 'package:chat_with_firebase/services/auth_service.dart';
import 'package:chat_with_firebase/services/database_service.dart';
import 'package:chat_with_firebase/services/group_service.dart';
import 'package:chat_with_firebase/services/notification_service.dart';
import 'package:chat_with_firebase/views/chat_screen.dart';
import 'package:chat_with_firebase/views/group_chat_screen.dart';
import 'package:chat_with_firebase/views/group_screen.dart';
import 'package:chat_with_firebase/views/home_screen.dart';
import 'package:chat_with_firebase/views/login_screen.dart';
import 'package:chat_with_firebase/views/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  List<GroupModel> groupAndSingleChats = [];
  GroupService groupService = GroupService();
  DatabaseService databaseService = DatabaseService();
  Stream? getAllGroupsAndChats;
  AuthService authService = AuthService();
  FirebaseAuth auth = FirebaseAuth.instance;
  DatabaseService service = DatabaseService();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  NotificationService notificationService = NotificationService();
  Stream? user;
  Stream? notification;
  @override
  void initState() {
    getAllGroupsAndChats =
        databaseService.getAllGroupsAndChats(auth.currentUser!.uid);
    user = service.getAllUsers(auth.currentUser!.uid);
    setupInteractedMessage();
    WidgetsBinding.instance.addObserver(this);
    notification =
        notificationService.getNotifications(auth.currentUser!.email!);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    log('this is payload ${message.data['payLoad']}');

    if (message.data['payLoad'] != null) {
      var data = jsonDecode(message.data['payLoad']);
      log(data['isGroup'].runtimeType.toString());
      log(data['isGroup'].toString());
      if (data['isGroup'] == true) {
        await navigatorKey.currentState!.push(MaterialPageRoute(
            builder: (context) => GroupChatScreen(
                groupName: data['groupName'],
                groupId: data['groupId'],
                groupMembers: data['groupMembers'])));
      } else {
        await navigatorKey.currentState!.push(MaterialPageRoute(
            builder: (context) => ChatScreen(
                username: data['username'],
                userUid: data['userUid'],
                userEmail: data['userEmail'])));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DateTime time = DateTime.now();
    switch (state) {
      case AppLifecycleState.resumed:
        log('app resumed');
        service.updateUserSingleField(auth.currentUser!.uid,
            {'isOnline': true, 'lastOnline': time, 'typingWith': ''});
        break;
      case AppLifecycleState.paused:
        log('app paused');
        service.updateUserSingleField(auth.currentUser!.uid,
            {'isOnline': false, 'lastOnline': time, 'typingWith': ''});
        break;
      case AppLifecycleState.inactive:
        log('app inactive');
        service.updateUserSingleField(auth.currentUser!.uid,
            {'isOnline': false, 'lastOnline': time, 'typingWith': ''});
        break;
      case AppLifecycleState.detached:
      default:
        log('app detached');
        service.updateUserSingleField(auth.currentUser!.uid,
            {'isOnline': false, 'lastOnline': time, 'typingWith': ''});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: const Text('Conversations'),
        actions: [
          Badge(
              label: StreamBuilder(
                stream: notification,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.connectionState == ConnectionState.none) {
                    return const Text('no data');
                  }
                  var data= snapshot.data.docs;
                  log(data.length.toString());
                  return  Text(data.length.toString());
                },
              ),
              // ValueListenableBuilder(
              //     builder: (context, value, child) =>
              //         Text(notificationcount.value.toString()),
              //     valueListenable: notificationcount),
              child: IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> const NotificationScreen()));
                  }, icon: const Icon(Icons.more_vert))),
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GroupsScreen()));
              },
              icon: const Icon(Icons.group)),
          IconButton(
              onPressed: () async {
                try {
                  await DatabaseService().updateUserSingleField(
                      auth.currentUser!.uid,
                      {'isOnline': false, 'lastOnline': DateTime.now()});
                  authService.userSignOut();
                  // await FirebaseAuth.instance.signOut();
                  Fluttertoast.showToast(msg: 'Signed out successfully');
                  // ignore: use_build_context_synchronously
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false);
                } catch (e) {
                  log(e.toString());
                  Fluttertoast.showToast(msg: e.toString());
                }
              },
              icon: const Icon(Icons.exit_to_app))
        ],
      ),
      body: StreamBuilder(
        stream: getAllGroupsAndChats,
        builder: <DocumentSnapshot>(context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  log(snapshot.data.length.toString());
                  GroupModel data = snapshot.data[index];

                  String id = (data.senderId == auth.currentUser!.uid
                      ? data.receiverId
                      : data.senderId)!;

                  return data.isGroup
                      ? Card(
                          child: ListTile(
                              onTap: () {
                                if (data.members!
                                    .contains(auth.currentUser!.uid)) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => GroupChatScreen(
                                                groupName: data.groupName ?? '',
                                                groupId: data.groupId ?? '',
                                                groupMembers: data.members!,
                                              )));
                                } else {
                                  Fluttertoast.showToast(
                                      msg: 'Join Group First');
                                }
                              },
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              tileColor: Colors.orange,
                              textColor: Colors.white,
                              title: Text(
                                data.groupName ?? 'hei',
                                textAlign: TextAlign.justify,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                children: [
                                  const Text('Participants: '),
                                  Text(data.members!.length.toString()),
                                ],
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.lightBlueAccent.withOpacity(.8),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onPressed: data.members!
                                        .contains(auth.currentUser!.uid)
                                    ? null
                                    : () {
                                        groupService
                                            .joinGroup(
                                                auth.currentUser!.uid,
                                                data.groupId ?? '',
                                                'zubair',
                                                data.groupName ?? '')
                                            .then((e) {
                                          Fluttertoast.showToast(msg: 'Joined');
                                        });
                                      },
                                child: Text(data.members!
                                        .contains(auth.currentUser!.uid)
                                    ? 'Joined'
                                    : 'Join'),
                              )),
                        )
                      : Card(
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                          username: 'zubair',
                                          userUid: id,
                                          userEmail: data.senderEmail ==
                                                  auth.currentUser!.email
                                              ? data.receiverEmail!
                                              : data.senderEmail!)));
                            },
                            textColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            tileColor: Colors.blueAccent.withOpacity(.5),
                            title: Text(
                              data.senderEmail == auth.currentUser!.email
                                  ? data.receiverEmail!
                                  : data.senderEmail!,
                              textAlign: TextAlign.justify,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              data.lastMessage ?? '',
                              textAlign: TextAlign.justify,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                                onPressed: () {
                                  // FirebaseFirestore.instance.collection('chat_place').doc('${data.receiverId}-${data.senderId}').delete();
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.orange,
                                )),
                          ),
                        );
                },
              );
            }
          } else {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
          }
          return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HomeScreen()));
          // sendPushNotification();
          // _showNotificationWithoutSound();
        },
        backgroundColor: Colors.orange,
        child: const Icon(
          Icons.message,
          color: Colors.white,
        ),
      ),
    );
  }

  Future _showNotificationWithoutSound() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'unique_notification_channel_id', 'aslkdfj',
        playSound: false, importance: Importance.max, priority: Priority.high);

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'New Post',
      'How to Show Notification in Flutter',
      platformChannelSpecifics,
      payload: 'No_Sound',
    );
  }

  sendPushNotification() async {
    String receiverToken =
        'fRphWwhOTN6zYEVbTqWE8Z:APA91bGdgcMj01Ex0iX7sIqzat5zxMPDrcm3-HetHSGY556o_yB313BBdKEQaOhUuKmuvtAv0aGUFfHOBLEEedZjUNQMm5yM-EfccAF4Vu1R2oT0LyfiRKfDDM7I-R-wsZ0t8QKd1_bv';
    String serverKey =
        'AAAAHL0xMks:APA91bE6bKAuxm0-vXKSchtSFlrNGbUUkld-EklHhYy2t5oIlaRjPMyhe5ChBtYM-rmOQ0XRZ53whHdZdfItac1xOELxuaIBML4xd9CsLintoS0hTgSON4w2V9l8Tu9UBr1INLIl3L8K';
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(
          {
            'notification': {
              'body': 'This is notification body',
              'title': 'Chatify',
            },
            'priority': 'high',
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
            },
            'to': receiverToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        log('Notification sent successfully');
      } else {
        log('Failed to send notification. Status code: ${response.statusCode}');
        log(response.body);
      }
    } catch (e) {
      log("Error sending push notification: $e");
    }
  }
}
