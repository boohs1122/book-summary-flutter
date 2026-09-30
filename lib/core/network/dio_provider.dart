import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  ref.onDispose(dio.close);
  return dio;
});
