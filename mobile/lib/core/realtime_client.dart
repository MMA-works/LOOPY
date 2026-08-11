import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/chat_models.dart';
import 'backend_config.dart';

class RealtimeClient {
  RealtimeClient(
      {required this.token,
      required this.onMessage,
      required this.onStatus,
      required this.onError,
      required this.onConnectionChanged});
  final String token;
  final void Function(ChatMessage message) onMessage;
  final void Function(MessageStatusEvent event) onStatus;
  final void Function(String message) onError;
  final void Function(bool connected) onConnectionChanged;
  StompClient? _client;

  void connect() {
    _client = StompClient(
      config: StompConfig(
        url: BackendConfig.webSocketUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 3),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: (frame) {
          onConnectionChanged(true);
          _client!.subscribe(
              destination: '/user/queue/message-status',
              callback: (frame) {
                if (frame.body != null) {
                  onStatus(MessageStatusEvent.fromJson(
                      jsonDecode(frame.body!) as Map<String, dynamic>));
                }
              });
          _client!.subscribe(
              destination: '/user/queue/messages',
              callback: (frame) {
                if (frame.body != null) {
                  onMessage(ChatMessage.fromJson(
                      jsonDecode(frame.body!) as Map<String, dynamic>));
                }
              });
          _client!.subscribe(
              destination: '/user/queue/errors',
              callback: (frame) {
                if (frame.body != null) {
                  final data = jsonDecode(frame.body!) as Map<String, dynamic>;
                  onError((data['message'] ?? 'Message rejected') as String);
                }
              });
        },
        onDisconnect: (_) => onConnectionChanged(false),
        onWebSocketError: (error) {
          onConnectionChanged(false);
          onError('Real-time connection unavailable');
        },
        onStompError: (frame) =>
            onError(frame.body ?? 'Real-time protocol error'),
      ),
    )..activate();
  }

  void acknowledgeDelivered(String messageId) =>
      _send('/app/chat.delivered', {'messageId': messageId});

  void markConversationRead(String conversationId) =>
      _send('/app/chat.read', {'conversationId': conversationId});

  void _send(String destination, Map<String, dynamic> body) {
    if (!(_client?.connected ?? false)) {
      throw StateError('Real-time connection is reconnecting');
    }
    _client!.send(
        destination: destination,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'});
  }

  void sendText(
      {required String conversationId,
      required String text,
      required String clientMessageId}) {
    if (!(_client?.connected ?? false)) {
      throw StateError('Real-time connection is reconnecting');
    }
    _client!.send(
        destination: '/app/chat.send',
        body: jsonEncode({
          'conversationId': conversationId,
          'text': text,
          'clientMessageId': clientMessageId
        }),
        headers: {'content-type': 'application/json'});
  }

  void dispose() => _client?.deactivate();
}
