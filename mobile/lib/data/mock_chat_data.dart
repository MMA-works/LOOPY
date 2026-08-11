import '../models/chat_models.dart';

class MockChatData {
  static const currentUser = ChatUser(
    id: 'me',
    name: 'Ayan Malik',
    handle: '@ayan',
    initials: 'AM',
    colorValue: 0xFF5B4FDB,
    isOnline: true,
  );

  static const users = <ChatUser>[
    ChatUser(
        id: 'sara',
        name: 'Sara Khan',
        handle: '@sara',
        initials: 'SK',
        colorValue: 0xFFE86A92,
        isOnline: true),
    ChatUser(
        id: 'hamza',
        name: 'Hamza Ali',
        handle: '@hamza',
        initials: 'HA',
        colorValue: 0xFF2B9C91),
    ChatUser(
        id: 'noor',
        name: 'Noor Fatima',
        handle: '@noor',
        initials: 'NF',
        colorValue: 0xFFF39A4B,
        isOnline: true),
    ChatUser(
        id: 'zain',
        name: 'Zain Ahmed',
        handle: '@zain',
        initials: 'ZA',
        colorValue: 0xFF4A82D8),
  ];

  static List<ChatMessage> messagesFor(String userId) => <ChatMessage>[
        ChatMessage(
          id: '1',
          senderId: userId,
          text: 'Assalam-o-alaikum! Kal ka plan confirm hai?',
          createdAt: DateTime.now().subtract(const Duration(minutes: 24)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: '2',
          senderId: currentUser.id,
          text: 'Wa-alaikum-salam, bilkul. Main 6 baje pohanch jaunga.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 21)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: '3',
          senderId: userId,
          type: MessageType.voice,
          voiceDuration: const Duration(seconds: 18),
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          status: MessageStatus.delivered,
        ),
        ChatMessage(
          id: '4',
          senderId: currentUser.id,
          text: 'Perfect, phir milte hain!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          status: MessageStatus.delivered,
        ),
      ];
}
