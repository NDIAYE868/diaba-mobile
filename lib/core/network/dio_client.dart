import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_config.dart';
import '../storage/token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  return DioClient(tokenStorage).dio;
});

class DioClient {
  late final Dio dio;
  final TokenStorage _tokenStorage;

  DioClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.fullApiUrl,
        connectTimeout: const Duration(seconds: AppConfig.connectTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConfig.receiveTimeoutSeconds),
        sendTimeout: const Duration(seconds: AppConfig.sendTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(_tokenStorage, dio),
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
      ),
    ]);
  }
}

class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._tokenStorage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          await _tokenStorage.clearTokens();
          _isRefreshing = false;
          handler.next(err);
          return;
        }

        // Tenter de rafraîchir le token
        final response = await _dio.post(
          '${AppConfig.fullApiUrl}/auth/jwt/refresh/',
          data: {'refresh': refreshToken},
          options: Options(
            headers: {'Authorization': null}, // pas de token pour le refresh
          ),
        );

        final newAccessToken = response.data['access'] as String;
        await _tokenStorage.saveAccessToken(newAccessToken);

        // Réessayer la requête originale
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        _isRefreshing = false;
        handler.resolve(retryResponse);
      } catch (e) {
        _isRefreshing = false;
        await _tokenStorage.clearTokens();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}

/// Exception formatée pour l'app
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  factory AppException.fromDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = 'La connexion a expiré. Vérifiez votre connexion.';
        break;
      case DioExceptionType.connectionError:
        message = 'Impossible de se connecter au serveur.';
        break;
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          // Essayer d'extraire le message d'erreur de l'API
          message = _extractErrorMessage(data);
        } else {
          message = _httpErrorMessage(statusCode);
        }
        break;
      default:
        message = 'Une erreur inattendue est survenue.';
    }

    return AppException(message, statusCode: statusCode);
  }

  static String _extractErrorMessage(Map<String, dynamic> data) {
    if (data.containsKey('detail')) return data['detail'].toString();
    if (data.containsKey('message')) return data['message'].toString();
    if (data.containsKey('error')) return data['error'].toString();
    // Erreurs de validation (champ → [messages])
    final entries = data.entries.where((e) => e.value is List).toList();
    if (entries.isNotEmpty) {
      final field = entries.first.key;
      final msgs = (entries.first.value as List).join(', ');
      return '$field: $msgs';
    }
    return 'Une erreur est survenue.';
  }

  static String _httpErrorMessage(int? code) {
    switch (code) {
      case 400: return 'Requête invalide.';
      case 401: return 'Non autorisé. Veuillez vous connecter.';
      case 403: return 'Accès refusé.';
      case 404: return 'Ressource introuvable.';
      case 500: return 'Erreur serveur. Réessayez plus tard.';
      default: return 'Erreur HTTP $code.';
    }
  }

  @override
  String toString() => message;
}
