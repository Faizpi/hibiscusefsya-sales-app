/// Konfigurasi API base URL dan constants.
class AppConfig {
  // Ganti URL ini sesuai dengan domain website Anda
  static const String baseUrl = 'https://sales.hibiscusefsya.com/api/v1';

  // Untuk development lokal (uncomment salah satu):
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000/api/v1';  // iOS Simulator
  // static const String baseUrl = 'http://192.168.x.x:8000/api/v1'; // Physical device (ganti IP)

  static const Duration timeout = Duration(seconds: 30);
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
