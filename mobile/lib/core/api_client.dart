import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/chat_models.dart';
import 'backend_config.dart';

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => message;
}

class AuthenticatedUser {
  const AuthenticatedUser(
      {required this.id, required this.username, required this.name});
  final String id;
  final String username;
  final String name;
  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) =>
      AuthenticatedUser(
          id: json['id'] as String,
          username: json['username'] as String,
          name: json['name'] as String);
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      };

  Future<Map<String, dynamic>> post(
          String path, Map<String, dynamic> body) async =>
      _decode(await _client.post(Uri.parse('${BackendConfig.apiBaseUrl}$path'),
          headers: _headers, body: jsonEncode(body)));
  Future<dynamic> get(String path, {Map<String, String>? query}) async =>
      _decode(await _client.get(
          Uri.parse('${BackendConfig.apiBaseUrl}$path')
              .replace(queryParameters: query),
          headers: _headers));

  Future<ChatMessage> uploadVoice(String conversationId,
      {required String clientMessageId,
      required Duration duration,
      required List<int> bytes,
      required String filename,
      required String contentType}) async {
    final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${BackendConfig.apiBaseUrl}/api/v1/conversations/$conversationId/voice'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['clientMessageId'] = clientMessageId;
    request.fields['durationMs'] = duration.inMilliseconds.toString();
    final parts = contentType.split('/');
    request.files.add(http.MultipartFile.fromBytes('file', bytes,
        filename: filename,
        contentType: parts.length == 2 ? MediaType(parts[0], parts[1]) : null));
    return ChatMessage.fromJson(
        _decode(await http.Response.fromStream(await request.send())));
  }

  Future<ChatMessage> uploadImage(String conversationId,
      {required String clientMessageId,
      required List<int> bytes,
      required String filename,
      required String contentType}) async {
    final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${BackendConfig.apiBaseUrl}/api/v1/conversations/$conversationId/images'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['clientMessageId'] = clientMessageId;
    final parts = contentType.split('/');
    request.files.add(http.MultipartFile.fromBytes('file', bytes,
        filename: filename,
        contentType: parts.length == 2 ? MediaType(parts[0], parts[1]) : null));
    return ChatMessage.fromJson(
        _decode(await http.Response.fromStream(await request.send())));
  }

  dynamic _decode(http.Response response) {
    final data = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['detail'] ?? data['title'] ?? 'Request failed') as String
          : 'Request failed';
      throw ApiException(message, response.statusCode);
    }
    return data;
  }

  Future<List<int>> voiceBytes(String path) async {
    final response = await _client.get(
        Uri.parse(BackendConfig.absoluteUrl(path)),
        headers: {if (token != null) 'Authorization': 'Bearer $token'});
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Could not load voice message', response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<List<int>> imageBytes(String path) async {
    final response = await _client.get(
        Uri.parse(BackendConfig.absoluteUrl(path)),
        headers: {if (token != null) 'Authorization': 'Bearer $token'});
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Could not load image message', response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<List<ChatUser>> users() async => ((await get('/api/v1/users')) as List)
      .map((item) => ChatUser.fromJson(item as Map<String, dynamic>))
      .toList();
  Future<List<ConversationModel>> conversations() async => ((await get(
          '/api/v1/conversations')) as List)
      .map((item) => ConversationModel.fromJson(item as Map<String, dynamic>))
      .toList();
  Future<ConversationModel> openDirect(String userId) async =>
      ConversationModel.fromJson(
          await post('/api/v1/conversations/direct', {'userId': userId}));
  Future<(List<ChatMessage>, String?)> messages(String conversationId,
      {String? before}) async {
    final data = await get('/api/v1/conversations/$conversationId/messages',
            query: {'limit': '50', if (before != null) 'before': before})
        as Map<String, dynamic>;
    return (
      ((data['messages'] as List)
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList()),
      data['nextCursor'] as String?
    );
  }
}
