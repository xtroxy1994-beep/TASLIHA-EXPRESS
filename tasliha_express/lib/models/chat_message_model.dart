import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}

enum MessageType { text, image, system }

class ChatRoomModel {
  final String id;
  final String requestId;
  final String clientId;
  final String techId;
  final String clientName;
  final String techName;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatRoomModel({
    required this.id,
    required this.requestId,
    required this.clientId,
    required this.techId,
    required this.clientName,
    required this.techName,
    this.lastMessage = '',
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatRoomModel(
      id: docId,
      requestId: map['requestId'] ?? '',
      clientId: map['clientId'] ?? '',
      techId: map['techId'] ?? '',
      clientName: map['clientName'] ?? '',
      techName: map['techName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: map['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'clientId': clientId,
      'techId': techId,
      'clientName': clientName,
      'techName': techName,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'unreadCount': unreadCount,
    };
  }
}
