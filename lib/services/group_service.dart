import 'package:chat_with_firebase/models/group_model.dart';
import 'package:chat_with_firebase/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference userCollecRef =
      FirebaseFirestore.instance.collection('users');
  CollectionReference groupCollecRef =
      FirebaseFirestore.instance.collection('groups');

  createGroup(String userName, String userId, String groupName) async {
    GroupModel groupModel = GroupModel(
      isGroup: true,
        groupName: groupName,
        groupAdmin: '${userId}_$userName',
        createdAt: Timestamp.now(),
        members: [],
        groupId: '',
        lastMessage: '',
        lastMessageSender: '');
    DocumentReference groupDocRef =
        await groupCollecRef.add(groupModel.toJson());
    await groupDocRef.update({
      'groupId': groupDocRef.id,
      'members': FieldValue.arrayUnion([userId])
    });
    await userCollecRef.doc(userId).update({
      'groups': ['${groupDocRef.id}_$groupName']
    });
  }

  Stream<QuerySnapshot> getAllGroups() {
    return groupCollecRef.snapshots();
  }

  
  Stream<List<Map<String, dynamic>>> getGroupsForMember(String memberId) {
    return getAllGroups().map((QuerySnapshot querySnapshot) {
     
      final notMemberGroups = querySnapshot.docs.where((group) {
        final members = group['members'] as List<dynamic>;
        return members.contains(memberId);
      }).toList();

     
      final notMemberGroupsData = notMemberGroups.map((group) {
        return group.data() as Map<String, dynamic>;
      }).toList();

      return notMemberGroupsData;
    });
  }

  joinGroup(
      String userId, String groupId, String userName, String groupName) async {
    await groupCollecRef.doc(groupId).update({
      'members': FieldValue.arrayUnion([userId])
    });
    await userCollecRef.doc(userId).update({
      'groups': FieldValue.arrayUnion(['${groupId}_$groupName'])
    });
  }

  Stream<QuerySnapshot> getMessages(String groupId) {
    var data = groupCollecRef
        .doc(groupId)
        .collection('messages')
        .where('isDeleted', isEqualTo: false)
        .orderBy('timeStamp', descending: true)
        .snapshots();

    return data;
  }

  sendMessageToGroup({
    required String groupId,
    required String senderId,
    String? textMessage,
    required String senderName,
    bool? isLocation,
    String? lat,
    String? long,
    String? senderEmail,
    bool? isDeleted,
    String? documentLink,
    String? imageLink,
    String? fileName,
    String? locationLink,
    String? locationScreenshot,
    String? messageId,
  }) async {
    Message messageToSend = Message(
        isLocation: isLocation??false,
        latitude: lat??'',
        longitude: long??'',
        senderId: senderId,
        senderEmail: senderEmail??'',
        isDeleted: isDeleted??false,
        receiverId: groupId,
        timestamp: Timestamp.now(),
        textMessage: textMessage ?? '',
        documentLink: documentLink??'',
        imageLink: imageLink??'',
        fileName: fileName??'',
        locationLink: locationLink??'',
        locationScreenshot: locationScreenshot??'',
        messageId: messageId,
        );
    DocumentReference messageRef = await groupCollecRef
        .doc(groupId)
        .collection('messages')
        .add(messageToSend.toMap());
    await messageRef.update({'messageId': messageRef.id});
    await groupCollecRef
        .doc(groupId)
        .update({'lastMessage': textMessage, 'lastMessageSender': senderName});
  }
}
