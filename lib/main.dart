import 'dart:convert';
import 'dart:developer';
import 'package:chat_with_firebase/services/fcm_service.dart';
import 'package:chat_with_firebase/services/notification_service.dart';
import 'package:chat_with_firebase/views/chat_screen.dart';
import 'package:chat_with_firebase/views/login_screen.dart';
import 'package:chat_with_firebase/views/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
//  Add stream controller
final _messageStreamController = BehaviorSubject<RemoteMessage>();
//  Define the background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  var payloadData = jsonDecode(message.data['payLoad']);
  log('..... ${payloadData['username']}');
  if (payloadData.isNotEmpty) {
    navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (context) => ChatScreen(
            username: payloadData['username'],
            userUid: payloadData['userUid'],
            userEmail: payloadData['userEmail'])));
  }
  log('this is data ${message.data['payLoad']}');
  // log("Handling a background message: ${message.messageId}");
  // log('Message data: ${message.data}');
  // log('Message notification: ${message.notification?.title}');
  // log('Message notification: ${message.notification?.body}');
}

ValueNotifier<String> ChatWith = ValueNotifier('');
ValueNotifier<int> notificationcount = ValueNotifier(0);
void notificationTapBackground(NotificationResponse notificationResponse) {
  log('this is payload ${notificationResponse.input}');
  log('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

void main() async {
  final bind = WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FcmService fcmService = FcmService();
  //Request permission
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  log('Permission granted: ${settings.authorizationStatus}');

  //Register with FCM
  String? token = await messaging.getToken();
  log('Registration Token=$token');

  //Set up foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    NotificationService notificationService = NotificationService();
    FirebaseAuth auth = FirebaseAuth.instance;
    var notificationData = jsonDecode(message.data['payLoad']);
    bool isGroup = notificationData['isGroup'];
    notificationcount.value++;
    if (isGroup == true) {
      if (ChatWith.value != notificationData['groupId']) {
        _showNotificationWithoutSound(
            message.notification!.title, message.notification!.body);
      }
    } else {
      log('this is notification data  ${notificationData['userUid']}');
      if (ChatWith.value != (notificationData['userUid'])) {
        notificationService.uploadNotificationaToFirebase(
            auth.currentUser!.email!,
            message.notification!.title ?? '',
            message.notification!.body ?? '');
        _showNotificationWithoutSound(
            message.notification!.title, message.notification!.body);
      }
    }

    log('Handling a foreground message: ${message.messageId}');
    log('Message data: ${message.data}');
    log('Message notification: ${message.notification?.title}');
    log('Message notification: ${message.notification?.body}');

    _messageStreamController.sink.add(message);
  });
  //Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
  // subscribe to a topic.
  const topic = 'app_promotion';
  await messaging.subscribeToTopic(topic);

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const android = AndroidInitializationSettings('app_icon');
  const iOS = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: android, iOS: iOS);

  await flutterLocalNotificationsPlugin!.initialize(initSettings,
      onDidReceiveNotificationResponse: notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future _showNotificationWithoutSound(String? title, String? body) async {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'unique_notification_channel_id', 'aslkdfj',
      playSound: false, importance: Importance.max, priority: Priority.high);

  var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin?.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'No_Sound',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String lastMessage = "";
  @override
  initState() {
    super.initState();
    localNotifiationInitialize();
  }

  _MyAppState() {
    _messageStreamController.listen((message) {
      setState(() {
        if (message.notification != null) {
          lastMessage = 'Received a notification message:'
              '\nTitle=${message.notification?.title},'
              '\nBody=${message.notification?.body},'
              '\nData=${message.data}';
        } else {
          lastMessage = 'Received a data message: ${message.data}';
        }
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: Colors.orange),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.orange, foregroundColor: Colors.white),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      home: auth.currentUser == null ? const LoginScreen() : const MainScreen(),
    );
  }

  Future onSelectNotification(String payload, BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("PayLoad"),
          content: Text("Payload : $payload"),
        );
      },
    );
  }

  void localNotifiationInitialize() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
// final DarwinInitializationSettings initializationSettingsDarwin =
//     DarwinInitializationSettings(
//         onDidReceiveLocalNotification: onDidReceiveNotificationResponse);

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }

    log(payload.toString());
  }
}
