import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:looply/app.dart';
import 'package:looply/core/api_client.dart';
import 'package:looply/models/chat_models.dart';
import 'package:looply/screens/auth_screen.dart';

void main() {
  testWidgets('original Looply brand mark renders', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: BrandMark())));
    expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
  });

  testWidgets('auth form validates required real credentials', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.tap(find.byKey(const Key('authSubmit')));
    await tester.pump();
    expect(find.text('Email or username is required'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  test('message JSON maps server fields', () {
    final message = ChatMessage.fromJson({
      'id': 'message-1',
      'conversationId': 'conversation-1',
      'senderId': 'user-1',
      'messageType': 'TEXT',
      'textContent': 'Hello',
      'status': 'SENT',
      'clientMessageId': 'client-1',
      'createdAt': '2026-08-10T12:00:00Z',
    });
    expect(message.conversationId, 'conversation-1');
    expect(message.text, 'Hello');
    expect(message.status, MessageStatus.sent);
  });

  test('voice message JSON maps playback metadata', () {
    final message = ChatMessage.fromJson({
      'id': 'voice-1',
      'conversationId': 'conversation-1',
      'senderId': 'user-1',
      'messageType': 'VOICE',
      'status': 'SENT',
      'createdAt': '2026-08-10T12:00:00Z',
      'voiceFileUrl': '/api/v1/voice/attachment-1/content',
      'voiceDuration': 3200,
      'voiceContentType': 'audio/webm',
    });
    expect(message.type, MessageType.voice);
    expect(message.voiceDuration, const Duration(milliseconds: 3200));
    expect(message.voiceContentType, 'audio/webm');
  });

  test('image message JSON maps authenticated image metadata', () {
    final message = ChatMessage.fromJson({
      'id': 'image-1',
      'conversationId': 'conversation-1',
      'senderId': 'user-1',
      'messageType': 'IMAGE',
      'status': 'SENT',
      'createdAt': '2026-08-10T12:00:00Z',
      'imageFileUrl': '/api/v1/images/attachment-1/content',
      'imageContentType': 'image/jpeg',
    });
    expect(message.type, MessageType.image);
    expect(message.imageFileUrl, '/api/v1/images/attachment-1/content');
    expect(message.imageContentType, 'image/jpeg');
  });

  test('message status event maps delivered and read timestamps', () {
    final event = MessageStatusEvent.fromJson({
      'messageId': 'message-1',
      'conversationId': 'conversation-1',
      'status': 'READ',
      'readAt': '2026-08-10T13:00:00Z',
    });
    expect(event.status, MessageStatus.read);
    expect(event.readAt, isNotNull);
  });

  test('API client sends bearer token and parses available users', () async {
    late http.Request captured;
    final client = ApiClient(client: MockClient((request) async {
      captured = request;
      return http.Response(
          jsonEncode([
            {
              'id': 'u1',
              'username': 'sara',
              'name': 'Sara Khan',
              'profilePhotoUrl': null
            }
          ]),
          200,
          headers: {'content-type': 'application/json'});
    }))
      ..token = 'test-token';

    final users = await client.users();
    expect(captured.headers['Authorization'], 'Bearer test-token');
    expect(users.single.handle, '@sara');
  });
}
