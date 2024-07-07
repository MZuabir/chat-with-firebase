import 'dart:async';
import 'package:chat_with_firebase/models/user_model.dart';
import 'package:chat_with_firebase/services/auth_service.dart';
import 'package:chat_with_firebase/services/database_service.dart';
import 'package:chat_with_firebase/services/group_service.dart';
import 'package:chat_with_firebase/views/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DatabaseService service = DatabaseService();
  AuthService authService = AuthService();
  FirebaseAuth auth = FirebaseAuth.instance;
  Stream? user;
  Stream? allgroups;
  Stream? combinedStream;
  Timer? timer;
  @override
  void initState() {
    user = service.getAllUsers(auth.currentUser!.uid);
    allgroups = GroupService().getAllGroups();
    // combinedStream = StreamGroup.merge([user!, allgroups!]);
    service.updateUserSingleField(auth.currentUser!.uid, {'isOnline': true});
    timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
  
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Users'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreamBuilder(
              stream: user,
              builder: <QuerySnapshot>(context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  final documents = snapshot.data!.docs;
                  if (documents.length > 0) {
                    return Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          UserModel datamodel =
                              UserModel.fromJson(documents[index].data());
                          // ignore: unused_local_variable
                          final lastOnlineTime = datamodel.lastOnline;
                          return Card(
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textColor: Colors.white,
                              tileColor: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                            username: datamodel.userName,
                                            userUid: datamodel.uid,
                                            userEmail: datamodel.userMail)));
                              },
                              title: Text(datamodel.userName),
                             
                              trailing: CircleAvatar(
                                radius: 10,
                                backgroundColor: datamodel.isOnline
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return const Center(child: Text('No users found!'));
                  }
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ));
  }

  String formatLastOnline(DateTime lastOnlineTime) {
    final now = DateTime.now();
    final difference = now.difference(lastOnlineTime);

    if (difference.inSeconds < 60) {
      return 'Online now';
    } else if (difference.inMinutes < 60) {
      return 'Last online ${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return 'Last online ${difference.inHours} hour\'s ago';
    } else if (difference.inDays == 1) {
      return 'Last online yesterday';
    } else if (difference.inDays < 7) {
      return 'Last online ${difference.inDays} day\'s ago';
    } else {
      return 'Last online ${DateFormat('MMM d, h:mm a').format(lastOnlineTime)}';
    }
  }
}
