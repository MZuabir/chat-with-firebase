import 'package:chat_with_firebase/models/group_model.dart';
import 'package:chat_with_firebase/services/group_service.dart';
import 'package:chat_with_firebase/views/group_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController textController = TextEditingController();

  GroupService groupService = GroupService();

  FirebaseAuth auth = FirebaseAuth.instance;
  Stream? getAllGroups;
  Stream? getJoinedGroups;
  @override
  void initState() {
    getAllGroups = groupService.getAllGroups();
    getJoinedGroups = groupService.getGroupsForMember(auth.currentUser!.uid);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Groups',
          ),
          scrolledUnderElevation: 0,
          bottom: TabBar(
              indicatorColor: Colors.blueAccent.withOpacity(.7),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              automaticIndicatorColorAdjustment: true,
              tabs: const [
                Tab(
                  child: Text(
                    'All Groups',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Tab(
                  child: Text(
                    'Joined',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ]),
        ),
        body: TabBarView(children: [
          AllGroupsTab(),
          joinedGroupTab(),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return CreateGroupDialog(
                  textController: textController,
                  onCreateTap: () async {
                    if (textController.text.trim().isNotEmpty) {
                      groupService
                          .createGroup('zubair', auth.currentUser!.uid,
                              textController.text.trim())
                          .then((value) {
                        Navigator.pop(context);
                        textController.clear();
                      });
                    }
                  },
                );
              },
            );
          },
          label: const Text('Create Group'),
        ),
      ),
    );
  }

  Widget AllGroupsTab() {
    return StreamBuilder(
      stream: getAllGroups,
      builder: <QuerySnapshot>(context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final documents = snapshot.data!.docs;
          if (documents.length > 0) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                GroupModel datamodel =
                    GroupModel.fromJson(documents[index].data());
                return Card(
                  child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        if (datamodel.members!
                            .contains(auth.currentUser!.uid)) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GroupChatScreen(
                                        groupName: datamodel.groupName ?? '',
                                        groupId: datamodel.groupId ?? '',
                                        groupMembers: datamodel.members!,
                                      )));
                        } else {
                          Fluttertoast.showToast(msg: 'Join Group First');
                        }
                      },
                      tileColor: Colors.orange,
                      textColor: Colors.white,
                      title: Text(datamodel.groupName ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Participants: ${datamodel.members!.length}'),
                          datamodel.lastMessage.isNotEmpty
                              ? Row(
                                  children: [
                                    Text(
                                      '${datamodel.lastMessageSender}: ',
                                      textAlign: TextAlign.start,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      datamodel.lastMessage,
                                      textAlign: TextAlign.start,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink()
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.lightBlueAccent.withOpacity(.8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed:
                            datamodel.members!.contains(auth.currentUser!.uid)
                                ? null
                                : () {
                                    groupService
                                        .joinGroup(
                                            auth.currentUser!.uid,
                                            datamodel.groupId ?? '',
                                            'zubair',
                                            datamodel.groupName ?? '')
                                        .then((e) {
                                      Fluttertoast.showToast(msg: 'Joined');
                                    });
                                  },
                        child: Text(
                            datamodel.members!.contains(auth.currentUser!.uid)
                                ? 'Joined'
                                : 'Join'),
                      )),
                );
              },
            );
          } else {
            return const Center(child: Text('No Groups found!'));
          }
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Center(child: Text('No Groups found!'));
      },
    );
  }

  Widget joinedGroupTab() {
    return StreamBuilder(
        stream: getJoinedGroups,
        builder: <QuerySnapshot>(context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final documents = snapshot;
            List<GroupModel> list = [];
            for (int i = 0; i < documents.data.length; i++) {
              list.add(GroupModel.fromJson(documents.data[i]));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: documents.data.length,
              itemBuilder: (context, index) {
                GroupModel datamodel =
                    GroupModel.fromJson(documents.data[index]);
                return Card(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      if (datamodel.members!.contains(auth.currentUser!.uid)) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GroupChatScreen(
                                    groupName: datamodel.groupName ?? '',
                                    groupId: datamodel.groupId ?? '',
                                    groupMembers: datamodel.members!,
                                    )));
                      } else {
                        Fluttertoast.showToast(msg: 'Join Group First');
                      }
                    },
                    textColor: Colors.white,
                    tileColor: Colors.orange,
                    title: Text(datamodel.groupName ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Participants: ${datamodel.members!.length}'),
                        datamodel.lastMessage.isNotEmpty
                            ? Row(
                                children: [
                                  Text(
                                    '${datamodel.lastMessageSender}: ',
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    datamodel.lastMessage,
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink()
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No Groups found!'));
          }
        }

        // } else if (snapshot.connectionState == ConnectionState.waiting) {
        //   return const Center(child: CircularProgressIndicator());
        // }

        // return const Center(child: Text('No Groups found!'));
        // },
        );
  }
}

class CreateGroupDialog extends StatelessWidget {
  const CreateGroupDialog({
    super.key,
    required this.onCreateTap,
    required this.textController,
  });
  final VoidCallback onCreateTap;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Center(child: Text('Create Group')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Group Name'),
          TextField(
            controller: textController,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white),
            onPressed: onCreateTap,
            child: const Text(
              'Create Group',
            ))
      ],
    );
  }
}
