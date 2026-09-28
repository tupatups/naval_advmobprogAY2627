import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naval_mobile/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Users are filtered in Dart so this query does not require a Firestore index.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final currentUserId = _firebaseAuth.currentUser?.uid;

    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final user = doc.data();
            return {...user, 'uid': user['uid'] ?? doc.id};
          })
          .where((user) => user['uid'].toString() != currentUserId)
          .toList();
    });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();
    final newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    final ids = [currentUserId, receiverId];
    ids.sort();
    final chatRoomId = ids.join('_');

    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessage(
    String userId,
    String otherUserId,
  ) {
    final ids = [userId, otherUserId];
    ids.sort();
    final chatRoomId = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;

    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}