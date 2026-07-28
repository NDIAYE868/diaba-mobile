import 'package:flutter/foundation.dart';

/// Configuration centrale de l'application Diaba
class AppConfig {
  AppConfig._();

  // ─── API ────────────────────────────────────────────────────────────────────
  /// URL de base de l'API Django (Ajuster selon l'environnement de test) :
  ///   - Web / Chrome / iOS Simulator / Docker : http://localhost:8000
  ///   - Android Emulator : http://10.0.2.2:8000
  ///   - Appareil physique sur réseau Wi-Fi : http://<IP_LOCALE_PC>:8000
  ///   - Production : https://api.diaba.sn
  static const String _envApiUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const String apiPrefix = '/api';
  static String get fullApiUrl => '$apiBaseUrl$apiPrefix';

  // ─── Timeouts ───────────────────────────────────────────────────────────────
  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 30;
  static const int sendTimeoutSeconds = 30;

  // ─── Storage Keys ───────────────────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeModeKey = 'theme_mode';

  // ─── Pagination ─────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ─── App Info ───────────────────────────────────────────────────────────────
  static const String appName = 'Diaba';
  static const String appTagline = 'Marketplace sénégalaise';
  static const String currency = 'XOF';
  static const String currencyLocale = 'fr-SN';
}
