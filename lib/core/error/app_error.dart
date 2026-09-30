import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract final class AppError {
  static const _loginMessage = '로그인에 실패했습니다. 다시 시도해 주세요.';
  static const _networkMessage = '서버에 연결할 수 없습니다. 연결 상태를 확인해 주세요.';
  static const _genericMessage = '요청을 처리하지 못했습니다. 다시 시도해 주세요.';

  static String message(Object error) {
    if (error is FirebaseAuthException) return _loginMessage;
    if (error is DioException) {
      if (error.error is FirebaseAuthException) return _loginMessage;
      if (_errorCode(error) == 'UNAUTHORIZED') return _loginMessage;
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return _networkMessage;
      }
    }
    return _genericMessage;
  }

  static String? _errorCode(DioException error) {
    final data = error.response?.data;
    if (data is! Map) return null;
    final body = data['error'];
    if (body is! Map) return null;
    return body['code'] as String?;
  }
}
