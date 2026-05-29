import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient api;
  final FlutterSecureStorage storage;

  AuthService({required this.api, required this.storage});

  // Returns null on success, or an error message string on failure
  Future<String?> register(String email, String password) async {
    try {
      final response = await api.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
      });
      await storage.write(
        key: 'access_token',
        value: response.data['access_token'],
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await api.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await storage.write(
        key: 'access_token',
        value: response.data['access_token'],
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await api.dio.get('/auth/me');
      return response.data;
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
  }

  Future<bool> hasToken() async {
    final token = await storage.read(key: 'access_token');
    return token != null;
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}