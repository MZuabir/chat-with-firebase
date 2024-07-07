import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:chat_with_firebase/services/database_service.dart';
import 'package:chat_with_firebase/services/message_service.dart';
import 'package:chat_with_firebase/services/group_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TaskLocationMap extends StatefulWidget {
  final LatLng latLng;
  final String receiverId;
  final bool fromImageClick;
  final bool fromgroupChat;
  final bool groupImageClick;
  const TaskLocationMap(
      {super.key,
      required this.latLng,
      required this.receiverId,
      this.groupImageClick = false,
      this.fromgroupChat = false,
      this.fromImageClick = false});

  @override
  State<TaskLocationMap> createState() => TaskLocationMapState();
}

class TaskLocationMapState extends State<TaskLocationMap> {
  MessageService messageService = MessageService();
  DatabaseService databaseService = DatabaseService();
  GroupService groupService = GroupService();
  FirebaseAuth auth = FirebaseAuth.instance;
  Uint8List imageData = Uint8List(0);
  
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  bool isLoading = false;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(30.3753, 69.3451),
    zoom: 19.4746,
  );

  late CameraPosition _kLake;
  @override
  void initState() {
    super.initState();
    _kLake = CameraPosition(target: widget.latLng, tilt: 0.0, zoom: 17.0);
    _goToTheLocation();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Share'),
      ),
      body: SafeArea(
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _kGooglePlex,
          compassEnabled: true,
          myLocationEnabled: true,
          onTap: widget.fromImageClick
              ? null
              : (argument) async {
                  _kLake = CameraPosition(
                      target: LatLng(argument.latitude, argument.longitude),
                      tilt: 0.0,
                      zoom: 17.0);
                  await _goToTheLocation();
                  isLoading=true;setState(() {
                    
                  });
                  await Future.delayed(const Duration(seconds: 2));
                  final GoogleMapController controller =
                      await _controller.future;
                  imageData = (await controller.takeSnapshot())!;
                  String imageUrl = await uploadImageToFirestorage(imageData);

                  log(imageUrl);
                  final url =
                      'https://maps.google.com/?q=${argument.latitude},${argument.longitude}';

                  await sendLocation(
                      widget.receiverId,
                      true,
                      argument.latitude.toString(),
                      argument.longitude.toString(),
                      url,
                      imageUrl);
                      isLoading=false;
                      setState(() {
                        
                      });
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                },
          markers: {
            Marker(
                markerId: const MarkerId("locationPin"),
                position: widget.latLng,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange)),
          },
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
      ),
      bottomSheet: widget.fromImageClick || widget.groupImageClick
          ? const SizedBox.shrink()
          : BottomSheet(
              backgroundColor: Colors.white,
              // elevation: 5,
              onClosing: () {},
              enableDrag: false,
              builder: (context) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20))),
                  height: 150,
                  child: Column(
                    children: [
                      isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : ListTile(
                              onTap: () async {
                                setState(() {
                                  isLoading = true;
                                });
                                Position position =
                                    await Geolocator.getCurrentPosition(
                                        desiredAccuracy: LocationAccuracy.high);
                                _kLake = CameraPosition(
                                    target: LatLng(
                                        position.latitude, position.longitude),
                                    tilt: 0.0,
                                    zoom: 17.0);
                                await _goToTheLocation();
                                await Future.delayed(
                                    const Duration(seconds: 2));
                                final GoogleMapController controller =
                                    await _controller.future;
                                imageData = (await controller.takeSnapshot())!;
                                String imageUrl =
                                    await uploadImageToFirestorage(imageData);
                                log(imageUrl);
                                final url =
                                    'https://maps.google.com/?q=${position.latitude},${position.longitude}';
                                await sendLocation(
                                    widget.receiverId,
                                    true,
                                    position.latitude.toString(),
                                    position.longitude.toString(),
                                    url,
                                    imageUrl);
                                setState(() {
                                  isLoading = false;
                                });
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                              },
                              splashColor: Colors.orange.withOpacity(0.3),
                              title: const Text('Share your curren location'),
                              leading: const Icon(CupertinoIcons.location),
                            ),
                      const Text('OR'),
                      const Text('Tap on any place from map to share'),
                    ],
                  ),
                );
              },
            ),
    );
  }

  sendLocation(String receiverId, bool isLocation, String lat, String long,
      String locationLink, String locationScreenShot) async {
    if (widget.fromgroupChat==true) {
      isLoading=true;setState(() {
        
      });
      //send message to group
      groupService.sendMessageToGroup(
      
          groupId: widget.receiverId,
          senderId: auth.currentUser!.uid,
          senderName: 'zubair',
          isLocation: true,
          locationLink: locationLink,
          locationScreenshot: locationScreenShot);
          isLoading=false;setState(() {
            
          });
    } else {
      isLoading=true;setState(() {
        
      });
      //send message to single chat
      await messageService.sendMessage(
        isGroup: false,
          receiverId: receiverId,
          isLocation: isLocation,
          lat: lat,
          long: long,
          locationLink: locationLink,
          locationScreenshot: locationScreenShot);
          isLoading=false;setState(() {
            
          });
    }
  }

  Future<String> uploadImageToFirestorage(
    Uint8List imageData,
  ) async {
    UploadTask uploadTask =
        databaseService.uploadImage(imageData, DateTime.now().toString());
    TaskSnapshot taskSnapshot = await uploadTask;
    final imageUrl = await taskSnapshot.ref.getDownloadURL();
    return imageUrl;
  }

  Future<void> _goToTheLocation() async {
    final GoogleMapController controller = await _controller.future;
    // EasyLoading.dismiss();

    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));

    controller.dispose();
  }
}
