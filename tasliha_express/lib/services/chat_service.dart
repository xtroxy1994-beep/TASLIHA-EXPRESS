import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../constants/app_constants.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String getChatRoomId(String requestId) => 'chat_$requestId';

  Future<void> initializeChatRoom({
    required String requestId,
    required String clientId,
    required String clientName,
    required String techId,
    required String techName,
  }) async {
    final roomId = getChatRoomId(requestId);
    final roomRef = _db.collection(AppConstants.chatsCollection).doc(roomId);
    final existing = await roomRef.get();
    if (!existing.exists) {
      await roomRef.set({
        'requestId': requestId,
        'clientId': clientId,
        'techId': techId,
        'clientName': clientName,
        'techName': techName,
        'lastMessage': 'تم فتح المحادثة',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await sendSystemMessage(requestId, 'تم قبول الطلب وفتح المحادثة بين العميل والفني');
    }
  }

  Future<void> sendMessage({
    required String requestId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final roomId = getChatRoomId(requestId);
    final batch = _db.batch();

    final msgRef = _db
        .collection(AppConstants.chatsCollection)
        .doc(roomId)
        .collection(AppConstants.messagesCollection)
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final roomRef = _db.collection(AppConstants.chatsCollection).doc(roomId);
    batch.update(roomRef, {
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> sendSystemMessage(String requestId, String content) async {
    final roomId = getChatRoomId(requestId);
    await _db
        .collection(AppConstants.chatsCollection)
        .doc(roomId)
        .collection(AppConstants.messagesCollection)
        .add({
      'senderId': 'system',
      'senderName': 'النظام',
      'content': content,
      'type': MessageType.system.name,
      'isRead': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ChatMessageModel>> watchMessages(String requestId) {
    final roomId = getChatRoomId(requestId);
    return _db
        .collection(AppConstants.chatsCollection)
        .doc(roomId)
        .collection(AppConstants.messagesCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<ChatRoomModel>> watchUserChatRooms(String userId) {
    // Watch all chats where user is either client or tech
    return _db
        .collection(AppConstants.chatsCollection)
        .where('clientId', isEqualTo: userId)
        .snapshots()
        .asyncMap((_) async {
      final clientRooms = await _db
          .collection(AppConstants.chatsCollection)
          .where('clientId', isEqualTo: userId)
          .get();
      final techRooms = await _db
          .collection(AppConstants.chatsCollection)
          .where('techId', isEqualTo: userId)
          .get();
      final allDocs = {...clientRooms.docs, ...techRooms.docs};
      return allDocs
          .map((d) => ChatRoomModel.fromMap(d.data(), d.id))
          .toList();
    });
  }

  Future<void> markMessagesAsRead(String requestId, String userId) async {
    final roomId = getChatRoomId(requestId);
    final snap = await _db
        .collection(AppConstants.chatsCollection)
        .doc(roomId)
        .collection(AppConstants.messagesCollection)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();
    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    if (snap.docs.isNotEmpty) {
      batch.update(
        _db.collection(AppConstants.chatsCollection).doc(roomId),
        {'unreadCount': 0},
      );
    }
    await batch.commit();
  }
}
