import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthSession {
  AuthSession(this.api, {FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();
  final ApiClient api;
  final FlutterSecureStorage storage;
  AuthenticatedUser? user;
  String? get token => api.token;

  Future<bool> restore() async {
    final saved = await storage.read(key: 'looply_access_token');
    if (saved == null) return false;
    api.token = saved;
    try {
      user = AuthenticatedUser.fromJson(
          await api.get('/api/v1/auth/me') as Map<String, dynamic>);
      return true;
    } catch (_) {
      await signOut();
      return false;
    }
  }

  Future<void> authenticate(
      {required String username,
      required String password,
      String? name,
      bool register = false}) async {
    final data = await api
        .post(register ? '/api/v1/auth/register' : '/api/v1/auth/login', {
      'username': username.trim(),
      'password': password,
      if (register) 'name': name!.trim()
    });
    api.token = data['accessToken'] as String;
    user = AuthenticatedUser.fromJson(data['user'] as Map<String, dynamic>);
    await storage.write(key: 'looply_access_token', value: api.token);
  }

  Future<void> signOut() async {
    api.token = null;
    user = null;
    await storage.delete(key: 'looply_access_token');
  }
}
