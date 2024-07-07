import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_with_firebase/helper_function/helper_functions.dart';
import 'package:chat_with_firebase/main.dart';
import 'package:chat_with_firebase/models/message_model.dart';
import 'package:chat_with_firebase/services/auth_service.dart';
import 'package:chat_with_firebase/services/database_service.dart';
import 'package:chat_with_firebase/services/fcm_service.dart';
import 'package:chat_with_firebase/services/message_service.dart';
import 'package:chat_with_firebase/views/image_display_screen.dart';
import 'package:chat_with_firebase/views/map_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen(
      {super.key,
      required this.username,
      required this.userUid,
      required this.userEmail});
  final String username;
  final String userUid;
  final String userEmail;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  HelperFunctions helperFunctions = HelperFunctions();
  MessageService messageService = MessageService();
  FirebaseAuth auth = FirebaseAuth.instance;
  DatabaseService databaseService = DatabaseService();
  AuthService authService = AuthService();
  FcmService fcmService = FcmService();
  TextEditingController messageController = TextEditingController();
  String currentUserId = '';
  Stream? chat;
  String image = '';
  XFile file = XFile('');
  ScrollController scrollController = ScrollController();
  List<String> messageIds = [];
  bool shouldDelete = false;
  Stream? checkUserStatus;
  String typingWith = '';
  String toFcm = '';
  StreamSubscription<DocumentSnapshot>? typingStatusListener;
  @override
  void initState() {
    ChatWith.value = widget.userUid;
    currentUserId = auth.currentUser!.uid;
    chat = messageService.getMessages(auth.currentUser!.uid, widget.userUid);
    checkUserStatus = authService.checkUserOnline(widget.userUid);
    getFcmofreceiverFromFirebase(widget.userEmail);
    checkTypingStatus();
    super.initState();
  }

  getFcmofreceiverFromFirebase(String mail) async {
    log(mail);
    toFcm = await fcmService.getFcmFromFirebase(mail);
    setState(() {});
  }

  @override
  void dispose() {
    setTypingStatus('');
    typingStatusListener?.cancel();
    ChatWith.value='';
    super.dispose();
  }

  void checkTypingStatus() {
    typingStatusListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userUid)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        final typingStatus = event.data()?['typingWith'] ?? '';
        log('this is listener $typingStatus');
        setState(() {
          typingWith = typingStatus;
        });
      }
    });
  }

  void setTypingStatus(String isTyping) {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser!.uid);
    userRef.update({'typingWith': isTyping});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setTypingStatus(widget.userUid);
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: ListTile(
            contentPadding: const EdgeInsets.only(top: 15),
            title: Text(
              widget.userEmail,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: typingWith == auth.currentUser!.uid
                ? const Text(
                    'Typing...',
                    style: TextStyle(color: Colors.white),
                  )
                : const SizedBox.shrink(),
          ),
          actions: [
            messageIds.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      messageService
                          .deleteMessage(
                              auth.currentUser!.uid, widget.userUid, messageIds)
                          .then((val) {
                        messageIds.clear();
                        setState(() {});
                      });
                    },
                    icon: const Icon(Icons.delete))
                : const SizedBox.shrink(),
            StreamBuilder(
              stream: checkUserStatus,
              builder: <DocumentSnapshot>(context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data != null) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: CircleAvatar(
                          radius: 10,
                          backgroundColor: snapshot.data['isOnline'] == true
                              ? Colors.green
                              : Colors.red
                          //  Colors.red,
                          ),
                    );
                  }
                } else {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                }
                return Container();
              },
            )
          ],
        ),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            StreamBuilder(
              stream: chat,
              builder: <QuerySnapshot>(context, snapshot) {
                // log(snapshot.data.docs.length.toString());
                if (snapshot.hasData) {
                  if (snapshot.data.docs.length > 0) {
                    return ListView.builder(
                      reverse: true,
                      controller: scrollController,
                      padding: const EdgeInsets.only(
                          top: 20, left: 10, right: 20, bottom: 100),
                      itemCount: snapshot.data.docs.length,
                      itemBuilder: (context, index) {
                        Message message =
                            Message.fromJson(snapshot.data.docs[index].data());
                        return GestureDetector(
                          onLongPress: () {
                            shouldDelete = !shouldDelete;
                            if (!messageIds.contains(message.messageId)) {
                              messageIds.add(message.messageId!);
                              log(messageIds.toString());
                            } else {
                              messageIds.remove(message.messageId);
                            }
                            setState(() {});
                            // messageService.deleteMessage(auth.currentUser!.uid,
                            //     widget.userUid, message.messageId!);
                          },
                          child: Stack(
                            children: [
                              Align(
                                  alignment: message.senderId == currentUserId
                                      ? Alignment.topRight
                                      : Alignment.topLeft,
                                  child: Stack(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5),
                                          child: message.textMessage.isNotEmpty
                                              ? Padding(
                                                  padding: EdgeInsets.only(
                                                      left: message.senderId ==
                                                              currentUserId
                                                          ? 100
                                                          : 0,
                                                      right: message.senderId ==
                                                              currentUserId
                                                          ? 0
                                                          : 100),
                                                  child: Container(
                                                      padding: const EdgeInsets.all(
                                                          10),
                                                      decoration: BoxDecoration(
                                                          color: message.senderId ==
                                                                  currentUserId
                                                              ? Colors.orange
                                                              : Colors
                                                                  .blueAccent,
                                                          borderRadius: BorderRadius.only(
                                                              topLeft: const Radius
                                                                  .circular(20),
                                                              topRight:
                                                                  const Radius.circular(
                                                                      20),
                                                              bottomLeft:
                                                                  Radius.circular(
                                                                      message.senderId == currentUserId
                                                                          ? 20
                                                                          : 0),
                                                              bottomRight:
                                                                  Radius.circular(message.senderId == currentUserId ? 0 : 20))),
                                                      child: Text(
                                                        message.textMessage,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      )),
                                                )
                                              : message.imageLink.isNotEmpty
                                                  ? Align(
                                                      alignment: message
                                                                  .senderId ==
                                                              currentUserId
                                                          ? Alignment.topRight
                                                          : Alignment.topLeft,
                                                      child: Card(
                                                        elevation: 4,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(
                                                            bottomRight: Radius
                                                                .circular(message
                                                                            .senderId ==
                                                                        auth.currentUser!
                                                                            .uid
                                                                    ? 0
                                                                    : 20),
                                                            bottomLeft: Radius
                                                                .circular(message
                                                                            .senderId ==
                                                                        auth.currentUser!
                                                                            .uid
                                                                    ? 20
                                                                    : 0),
                                                            topLeft: const Radius
                                                                .circular(20),
                                                            topRight: const Radius
                                                                .circular(20),
                                                          ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.only(
                                                              bottomRight:
                                                                  Radius.circular(
                                                                      message.senderId ==
                                                                              currentUserId
                                                                          ? 0
                                                                          : 20),
                                                              bottomLeft: Radius.circular(
                                                                  message.senderId ==
                                                                          currentUserId
                                                                      ? 20
                                                                      : 0),
                                                              topLeft: const Radius
                                                                  .circular(20),
                                                              topRight: const Radius
                                                                  .circular(20)),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.only(
                                                                    bottomRight:
                                                                        Radius.circular(message.senderId ==
                                                                                currentUserId
                                                                            ? 0
                                                                            : 20),
                                                                    bottomLeft: Radius.circular(
                                                                        message.senderId ==
                                                                                currentUserId
                                                                            ? 0
                                                                            : 20),
                                                                    topLeft:
                                                                        const Radius.circular(
                                                                            20),
                                                                    topRight:
                                                                        const Radius.circular(
                                                                            20))),
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                FocusScope.of(
                                                                        context)
                                                                    .unfocus();
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (context) => ImageDisplayScreen(
                                                                            imageTag:
                                                                                'image$index',
                                                                            imageUrl:
                                                                                message.imageLink)));
                                                              },
                                                              child: Hero(
                                                                tag:
                                                                    'image$index',
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: message
                                                                      .imageLink,
                                                                  height: 250,
                                                                  width: 200,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  placeholder: (context,
                                                                          url) =>
                                                                      const Center(
                                                                          child:
                                                                              CircularProgressIndicator()),
                                                                  errorWidget: (context,
                                                                          url,
                                                                          error) =>
                                                                      const Icon(
                                                                          Icons
                                                                              .error),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : message.documentLink
                                                          .isNotEmpty
                                                      ? GestureDetector(
                                                          onTap: () {
                                                            FocusScope.of(
                                                                    context)
                                                                .unfocus();
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute<
                                                                  dynamic>(
                                                                builder: (_) =>
                                                                    PDFViewerCachedFromUrl(
                                                                  url: message
                                                                      .documentLink,
                                                                  fileName: message
                                                                      .fileName!,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding: EdgeInsets.only(
                                                                left: message
                                                                            .senderId ==
                                                                        currentUserId
                                                                    ? 100
                                                                    : 0,
                                                                right: message
                                                                            .senderId ==
                                                                        currentUserId
                                                                    ? 0
                                                                    : 100),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration: BoxDecoration(
                                                                  color: message.senderId ==
                                                                          currentUserId
                                                                      ? Colors
                                                                          .orange
                                                                      : Colors
                                                                          .blueAccent,
                                                                  borderRadius: BorderRadius.only(
                                                                      topLeft:
                                                                          const Radius.circular(
                                                                              20),
                                                                      topRight:
                                                                          const Radius.circular(
                                                                              20),
                                                                      bottomLeft:
                                                                          Radius.circular(message.senderId == currentUserId
                                                                              ? 20
                                                                              : 0),
                                                                      bottomRight:
                                                                          Radius.circular(message.senderId == currentUserId
                                                                              ? 0
                                                                              : 20))),
                                                              child: Row(
                                                                children: [
                                                                  CircleAvatar(
                                                                    radius: 20,
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/images/pdf.png',
                                                                      height:
                                                                          30,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              10),
                                                                      child:
                                                                          Text(
                                                                        message
                                                                            .fileName!,
                                                                        style: const TextStyle(
                                                                            color:
                                                                                Colors.white),
                                                                        textAlign:
                                                                            TextAlign.justify,
                                                                        maxLines:
                                                                            3,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ))
                                                      : message.isLocation ==
                                                              true
                                                          ? Align(
                                                              alignment: message.senderId ==
                                                                      currentUserId
                                                                  ? Alignment
                                                                      .topRight
                                                                  : Alignment
                                                                      .topLeft,
                                                              child: Padding(
                                                                padding: EdgeInsets.only(
                                                                    left: message.senderId ==
                                                                            currentUserId
                                                                        ? 100
                                                                        : 0,
                                                                    right: message.senderId ==
                                                                            currentUserId
                                                                        ? 0
                                                                        : 100),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap:
                                                                      () async {
                                                                    Position
                                                                        position =
                                                                        await Geolocator.getCurrentPosition(
                                                                            desiredAccuracy:
                                                                                LocationAccuracy.high);
                                                                    // ignore: use_build_context_synchronously
                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) => TaskLocationMap(
                                                                                  latLng: LatLng(position.latitude, position.longitude),
                                                                                  receiverId: widget.userUid,
                                                                                  fromImageClick: true,
                                                                                )));
                                                                  },
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius: BorderRadius.only(
                                                                        topLeft:
                                                                            const Radius.circular(
                                                                                20),
                                                                        topRight:
                                                                            const Radius.circular(
                                                                                20),
                                                                        bottomLeft: Radius.circular(message.senderId ==
                                                                                currentUserId
                                                                            ? 20
                                                                            : 0),
                                                                        bottomRight: Radius.circular(message.senderId ==
                                                                                currentUserId
                                                                            ? 0
                                                                            : 20)),
                                                                    child: Card(
                                                                      elevation:
                                                                          5,
                                                                      child: Container(
                                                                          decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(message.senderId == currentUserId ? 20 : 0), bottomRight: Radius.circular(message.senderId == currentUserId ? 0 : 20))),
                                                                          child: Stack(
                                                                            fit:
                                                                                StackFit.loose,
                                                                            alignment:
                                                                                Alignment.bottomRight,
                                                                            children: [
                                                                              CachedNetworkImage(
                                                                                imageUrl: message.locationScreenshot!,
                                                                                height: 250,
                                                                                width: 250,
                                                                                fit: BoxFit.cover,
                                                                                errorWidget: (context, url, error) {
                                                                                  return const Center(
                                                                                    child: Icon(Icons.error),
                                                                                  );
                                                                                },
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.only(right: 10),
                                                                                child: ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                                                                    onPressed: () async {
                                                                                      await launchUrl(mode: LaunchMode.inAppWebView, Uri.parse(message.locationLink!));
                                                                                    },
                                                                                    child: const Text('Get Directions')),
                                                                              )
                                                                            ],
                                                                          )),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          : const SizedBox()),
                                    ],
                                  )),
                              messageIds.contains(message.messageId)
                                  ? Align(
                                      alignment:
                                          message.senderId == currentUserId
                                              ? Alignment.topRight
                                              : Alignment.topLeft,
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.yellow,
                                      ))
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        );
                      },
                    );
                  }
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return const Center(child: Text('No Chat.Send message!'));
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            offset: const Offset(0, 0),
                            blurRadius: 20,
                            spreadRadius: 6,
                            color: Colors.black.withOpacity(0.1))
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type message here'),
                        onSubmitted: (value) {
                          sendPushNotification(toFcm,
                              messageController.text.trim(), widget.userEmail, {
                            'isGroup': false,
                            'username': 'zubair',
                            'userUid': currentUserId,
                            'userEmail': auth.currentUser!.uid
                          });
                          sendTextMessage(messageController);
                          log('this is toFCM $toFcm');
                        },
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setTypingStatus(widget.userUid);
                          } else {
                            setTypingStatus('');
                          }
                        },
                        controller: messageController,
                      )),
                      PopupMenuButton(
                        splashRadius: 1,
                        offset: const Offset(0, -80),
                        icon: const Icon(Icons.link),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                                padding: const EdgeInsets.all(0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          String fileName =
                                              DateTime.now().toString();
                                          file =
                                              await helperFunctions.pickImage();
                                          final bytes = await file
                                              .readAsBytes(); // Uint8List
                                          final byteData =
                                              bytes.buffer.asByteData();
                                          UploadTask uploadTask =
                                              databaseService.uploadImage(
                                                  byteData.buffer.asUint8List(),
                                                  fileName);
                                          TaskSnapshot taskSnapshot =
                                              await uploadTask;
                                          final imageUrl = await taskSnapshot
                                              .ref
                                              .getDownloadURL();
                                          messageService.sendMessage(
                                              receiverEmail: widget.userEmail,
                                              receivername: widget.username,
                                              isGroup: false,
                                              receiverId: widget.userUid,
                                              imageLink: imageUrl);

                                          animateToDown();
                                        },
                                        icon: const Icon(Icons.image)),
                                    IconButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          FilePickerResult? result =
                                              await FilePicker.platform
                                                  .pickFiles(
                                            type: FileType.custom,
                                            onFileLoading: (p0) {
                                              return const CircularProgressIndicator();
                                            },
                                            allowCompression: true,
                                            allowMultiple: false,
                                            allowedExtensions: ['pdf'],
                                          );

                                          if (result != null) {
                                            File file =
                                                File(result.files.single.path!);
                                            final bytes = await file
                                                .readAsBytes(); // Uint8List
                                            final byteData =
                                                bytes.buffer.asByteData();
                                            List<String> name =
                                                file.path.split('/');
                                            log(name.toString());
                                            final String fileName = name.last;
                                            // String fileName = DateTime.now().toString();

                                            UploadTask uploadTask =
                                                databaseService.uploadImage(
                                                    byteData.buffer
                                                        .asUint8List(),
                                                    fileName);
                                            TaskSnapshot taskSnapshot =
                                                await uploadTask;
                                            final fileUrl = await taskSnapshot
                                                .ref
                                                .getDownloadURL();
                                            messageService.sendMessage(
                                                receiverEmail: widget.userEmail,
                                                receivername: widget.username,
                                                isGroup: false,
                                                receiverId: widget.userUid,
                                                fileName: fileName,
                                                documentLink: fileUrl);

                                            animateToDown();
                                          } else {
                                            // User canceled the picker
                                          }
                                        },
                                        icon: const Icon(Icons.file_copy)),
                                    IconButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          bool servicestatus = await Geolocator
                                              .isLocationServiceEnabled();
                                          LocationPermission permission =
                                              await Geolocator
                                                  .checkPermission();

                                          if (permission ==
                                              LocationPermission.denied) {
                                            permission = await Geolocator
                                                .requestPermission();
                                            if (permission ==
                                                LocationPermission.denied) {
                                              print(
                                                  'Location permissions are denied');
                                            } else if (permission ==
                                                LocationPermission
                                                    .deniedForever) {
                                              print(
                                                  "'Location permissions are permanently denied");
                                            } else {
                                              print(
                                                  "GPS Location service is granted");
                                            }
                                          } else {
                                            if (servicestatus == true) {
                                              Position position =
                                                  await Geolocator
                                                      .getCurrentPosition(
                                                          desiredAccuracy:
                                                              LocationAccuracy
                                                                  .high);
                                              // ignore: use_build_context_synchronously
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          // MapScreen(
                                                          //   lat: position
                                                          //       .latitude,
                                                          //   long: position
                                                          //       .longitude,
                                                          //   userId:
                                                          //       widget.userUid,
                                                          // )
                                                          TaskLocationMap(
                                                            latLng: LatLng(
                                                                position
                                                                    .latitude,
                                                                position
                                                                    .longitude),
                                                            receiverId:
                                                                widget.userUid,
                                                          )));

                                              // final url =
                                              //     'https://maps.google.com/?q=${position.latitude},${position.longitude}';
                                              // await messageService.sendMessage(
                                              //     widget.userUid,
                                              //     '',
                                              //     '',
                                              //     '',
                                              //     position.latitude.toString(),
                                              //     position.longitude.toString(),
                                              //     true,
                                              //     url);
                                            } else {
                                              Fluttertoast.showToast(
                                                  msg: 'Enable location first');
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.gps_fixed)),
                                  ],
                                ))
                          ];
                        },
                      ),
                      IconButton(
                          onPressed: () {
                            sendPushNotification(
                                toFcm,
                                messageController.text.trim(),
                                widget.userEmail, {
                              'isGroup': false,
                              'username': 'zubair',
                              'userUid': auth.currentUser!.uid,
                              'userEmail': auth.currentUser!.email
                            });
                            sendTextMessage(messageController);
                          },
                          icon: const Icon(Icons.send)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendTextMessage(TextEditingController textController) async {
    if (messageController.text.trim().isNotEmpty) {
      try {
        messageService.sendMessage(
          receiverEmail: widget.userEmail,
          receivername: widget.username,
          receiverId: widget.userUid,
          isGroup: false,
          textMessage: messageController.text.trim(),
        );

        messageController.clear();
        FocusScope.of(context).unfocus();
        setTypingStatus(''); //set empty string here
        animateToDown();
      } catch (e) {
        log(e.toString());
      }
    }
  }

  animateToDown() {
    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
    );
  }

  sendPushNotification(String receiverFcm, String notificationBody,
      String sendername, Map<String, dynamic> receiverdata) async {
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
              'body': notificationBody,
              'title': '${auth.currentUser!.email} sent you message',
            },
            'priority': 'high',
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              'payLoad': receiverdata
            },
            'to': receiverFcm,
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

class PDFViewerCachedFromUrl extends StatelessWidget {
  const PDFViewerCachedFromUrl(
      {Key? key, required this.url, required this.fileName})
      : super(key: key);

  final String url;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: const PDF().cachedFromUrl(
        url,
        placeholder: (double progress) => Center(child: Text('$progress %')),
        errorWidget: (dynamic error) => Center(child: Text(error.toString())),
      ),
    );
  }
}
