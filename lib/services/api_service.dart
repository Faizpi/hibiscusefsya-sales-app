import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final url = '${AppConfig.baseUrl}/$path';
    final uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    try {
      final response = await http
          .get(_uri(path, params), headers: _headers)
          .timeout(AppConfig.timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(AppConfig.timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(AppConfig.timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await http
          .delete(_uri(path), headers: _headers)
          .timeout(AppConfig.timeout);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  /// GET request returning raw bytes (for binary file downloads like PDF/Excel)
  Future<List<int>> getBytes(String path, {Map<String, String>? params}) async {
    try {
      final response = await http
          .get(_uri(path, params), headers: _headers)
          .timeout(const Duration(seconds: 120));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  /// POST request returning raw bytes (for export endpoints)
  Future<List<int>> postBytes(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 120));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, String>? filePaths,
    Map<String, List<String>>? fileListPaths,
  }) async {
    try {
      final uri = _uri(path);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value),
          );
        }
      }

      if (fileListPaths != null) {
        for (final entry in fileListPaths.entries) {
          for (final path in entry.value) {
            request.files.add(
              await http.MultipartFile.fromPath(entry.key, path),
            );
          }
        }
      }

      final streamedResponse = await request.send().timeout(AppConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message'] ?? 'Terjadi kesalahan.';
    throw ApiException(message, statusCode: response.statusCode);
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }

        final errors = data['errors'];
        if (errors is Map) {
          final messages = <String>[];
          for (final entry in errors.entries) {
            final value = entry.value;
            if (value is List) {
              messages.addAll(value.map((e) => e.toString()));
            } else if (value != null) {
              messages.add(value.toString());
            }
          }
          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }
    } catch (_) {
      // Ignore JSON parse failure and fallback to status text.
    }

    return 'Request gagal (${response.statusCode})';
  }
}
