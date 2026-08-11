enum MessageType { text, voice, image }

enum MessageStatus { sent, delivered, read }

class ChatUser {
  const ChatUser(
      {required this.id,
      required this.name,
      required this.handle,
      required this.initials,
      required this.colorValue,
      this.profilePhotoUrl,
      this.isOnline = false});
  final String id;
  final String name;
  final String handle;
  final String initials;
  final int colorValue;
  final String? profilePhotoUrl;
  final bool isOnline;

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
    return ChatUser(
        id: json['id'] as String,
        name: name,
        handle: '@${json['username']}',
        initials: initials,
        colorValue: 0xFF5B4FDB,
        profilePhotoUrl: json['profilePhotoUrl'] as String?);
  }
}

class ConversationModel {
  const ConversationModel(
      {required this.id,
      required this.participants,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final List<ChatUser> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        id: json['id'] as String,
        participants: (json['participants'] as List)
            .map((item) => ChatUser.fromJson(item as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  ChatUser otherThan(String currentUserId) =>
      participants.firstWhere((user) => user.id != currentUserId,
          orElse: () => participants.first);
}

class ChatMessage {
  const ChatMessage(
      {required this.id,
      this.conversationId = '',
      required this.senderId,
      required this.createdAt,
      required this.status,
      this.clientMessageId,
      this.type = MessageType.text,
      this.text,
      this.voiceDuration,
      this.voiceFileUrl,
      this.voiceContentType,
      this.imageFileUrl,
      this.imageContentType,
      this.readAt});
  final String id;
  final String conversationId;
  final String senderId;
  final DateTime createdAt;
  final MessageStatus status;
  final String? clientMessageId;
  final MessageType type;
  final String? text;
  final Duration? voiceDuration;
  final String? voiceFileUrl;
  final String? voiceContentType;
  final String? imageFileUrl;
  final String? imageContentType;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        senderId: json['senderId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        status: MessageStatus.values
            .byName((json['status'] as String).toLowerCase()),
        clientMessageId: json['clientMessageId'] as String?,
        type: MessageType.values
            .byName((json['messageType'] as String).toLowerCase()),
        text: json['textContent'] as String?,
        voiceFileUrl: json['voiceFileUrl'] as String?,
        voiceDuration: json['voiceDuration'] == null
            ? null
            : Duration(milliseconds: json['voiceDuration'] as int),
        voiceContentType: json['voiceContentType'] as String?,
        imageFileUrl: json['imageFileUrl'] as String?,
        imageContentType: json['imageContentType'] as String?,
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String).toLocal(),
      );

  ChatMessage withStatus(MessageStatus nextStatus, DateTime? nextReadAt) =>
      ChatMessage(
          id: id,
          conversationId: conversationId,
          senderId: senderId,
          createdAt: createdAt,
          status: nextStatus,
          clientMessageId: clientMessageId,
          type: type,
          text: text,
          voiceDuration: voiceDuration,
          voiceFileUrl: voiceFileUrl,
          voiceContentType: voiceContentType,
          imageFileUrl: imageFileUrl,
          imageContentType: imageContentType,
          readAt: nextReadAt ?? readAt);
}

class MessageStatusEvent {
  const MessageStatusEvent(
      {required this.messageId,
      required this.conversationId,
      required this.status,
      this.readAt});
  final String messageId;
  final String conversationId;
  final MessageStatus status;
  final DateTime? readAt;

  factory MessageStatusEvent.fromJson(Map<String, dynamic> json) =>
      MessageStatusEvent(
          messageId: json['messageId'] as String,
          conversationId: json['conversationId'] as String,
          status: MessageStatus.values
              .byName((json['status'] as String).toLowerCase()),
          readAt: json['readAt'] == null
              ? null
              : DateTime.parse(json['readAt'] as String).toLocal());
}
