import 'api_client.dart';
import 'auth_session.dart';

class AppServices {
  AppServices._() : api = ApiClient() {
    session = AuthSession(api);
  }
  static final AppServices instance = AppServices._();
  final ApiClient api;
  late final AuthSession session;
}
