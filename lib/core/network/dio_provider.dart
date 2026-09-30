import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

final dioProvider = Provider<Dio>((ref) {
  if (apiBaseUrl.isEmpty) {
    throw StateError('API_BASE_URL is required');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = await ref.read(authenticatedUserProvider.future);
          final token = await user.getIdToken();
          if (token == null) {
            throw StateError('Firebase ID token is unavailable');
          }
          options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        } catch (error) {
          handler.reject(DioException(requestOptions: options, error: error));
        }
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
