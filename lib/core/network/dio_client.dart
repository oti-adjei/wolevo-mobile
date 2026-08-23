import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env/app_environment.dart';
import '../logging/app_logger.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Base URL for the environment this binary was built for. Every mock
/// repository implements the same interface a Dio-backed one would, so swapping
/// them in requires no UI changes.
String get kApiBaseUrl => AppEnvironment.current.apiBaseUrl;

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final logger = ref.watch(loggerProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Breadcrumbs only — never the body. Responses carry addresses, order
        // contents and locker IDs, none of which belong in a crash report.
        logger.breadcrumb(
          'HTTP ${response.statusCode} ${response.requestOptions.method} '
          '${response.requestOptions.path}',
        );
        handler.next(response);
      },
      onError: (e, handler) {
        logger.error(
          'HTTP ${e.response?.statusCode ?? 'failed'} '
          '${e.requestOptions.method} ${e.requestOptions.path}',
          error: e,
          stackTrace: e.stackTrace,
        );
        handler.next(e);
      },
    ),
  );

  return dio;
});

/// Translates Dio failures into [ApiException], pulling out per-field messages
/// when the server sends them.
ApiException mapDioError(Object error) {
  if (error is! DioException) return ApiException.network;

  final status = error.response?.statusCode;
  final data = error.response?.data;

  if (status == 401) return ApiException.invalidCredentials;

  if (data is Map<String, dynamic>) {
    final fields = <String, String>{};
    final raw = data['fieldErrors'] ?? data['errors'];
    if (raw is Map) {
      raw.forEach((k, v) => fields['$k'] = '$v');
    }
    return ApiException(
      (data['message'] as String?) ?? ApiException.network.message,
      statusCode: status,
      fieldErrors: fields,
    );
  }

  return ApiException(ApiException.network.message, statusCode: status);
}
