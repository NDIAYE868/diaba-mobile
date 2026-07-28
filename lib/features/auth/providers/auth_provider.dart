import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(tokenStorageProvider),
  );
});

/// Fournit l'utilisateur courant (null si non connecté)
final authStateProvider = FutureProvider<User?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  final hasToken = await ref.read(tokenStorageProvider).hasToken();
  if (!hasToken) return null;
  return await repo.getCurrentUser();
});

/// Notifier pour les actions auth (login, register, logout)
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.read(authRepositoryProvider);
    final hasToken = await ref.read(tokenStorageProvider).hasToken();
    if (!hasToken) return null;
    return await repo.getCurrentUser();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email: email, password: password);
      ref.invalidate(authStateProvider);
      return user;
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      return await repo.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearTokens();
    state = const AsyncData(null);
    ref.invalidate(authStateProvider);
  }
}

class AuthRepository {
  final Dio _dio;
  final TokenStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/auth/jwt/create/', data: {
        'email': email,
        'password': password,
      });
      final access = response.data['access'] as String;
      final refresh = response.data['refresh'] as String;
      await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      return await getCurrentUser();
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      await _dio.post('/auth/users/', data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        're_password': password,
      });
      // Après inscription, retourner null (email à confirmer)
      return null;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/users/me/');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return User.fromJson(data);
      }
      throw const AppException('Format de réponse invalide');
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post('/auth/users/reset_password/', data: {'email': email});
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }
}
