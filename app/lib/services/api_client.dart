import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage;
  bool _isRefreshing = false;

  ApiClient({required this.storage})
      : dio = Dio(BaseOptions(
          baseUrl: 'https://api.macro-forge.org',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Only handle 401s, and don't try to refresh the refresh call itself
          final isAuthEndpoint =
              error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/register') ||
              error.requestOptions.path.contains('/auth/refresh');

          if (error.response?.statusCode == 401 &&
              !isAuthEndpoint &&
              !_isRefreshing) {
            _isRefreshing = true;
            final refreshed = await _tryRefresh();
            _isRefreshing = false;

            if (refreshed) {
              // Retry the original request with the new token
              final newToken = await storage.read(key: 'access_token');
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Uses the refresh token to get a new token pair. Returns true on success.
  Future<bool> _tryRefresh() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;

    try {
      // Use a bare Dio instance so we don't trigger the interceptor recursively
      final bareDio = Dio(BaseOptions(baseUrl: 'https://api.macro-forge.org'));
      final response = await bareDio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      await storage.write(key: 'access_token', value: response.data['access_token']);
      await storage.write(key: 'refresh_token', value: response.data['refresh_token']);
      return true;
    } on DioException {
      // Refresh failed — tokens are dead, clear them
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      return false;
    }
  }
}