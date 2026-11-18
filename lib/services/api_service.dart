import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../utils/storage.dart';

/// Error yang sudah ramah dibaca user (bukan raw exception).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  /// Pesan error pertama dari validasi Laravel (jika ada).
  String? get firstValidationError {
    for (final messages in errors.values) {
      if (messages.isNotEmpty) {
        return messages.first;
      }
    }

    return null;
  }

  @override
  String toString() => message;
}

/// Satu pintu untuk semua HTTP request ke Laravel.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  /// Dipanggil ketika server membalas 401 (token tidak valid / kedaluwarsa).
  static Future<void> Function()? onUnauthorized;

  final http.Client _client = http.Client();

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) {
    return _send('GET', path, query: query, auth: auth);
  }

  Future<Uint8List> getBytes(String url) async {
    final uri = Uri.parse(url);
    final baseUri = Uri.parse(ApiConfig.baseUrl);

    if (uri.origin != baseUri.origin) {
      throw ApiException('Alamat file tidak valid.');
    }

    final headers = <String, String>{
      'Accept': 'application/json, image/*',
      ...ApiConfig.mediaHeaders,
    };
    final token = await AppStorage.readToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _handle(response, didSendAuth: true, path: uri.path);
        throw ApiException(
          'File tidak dapat dimuat.',
          statusCode: response.statusCode,
        );
      }

      return response.bodyBytes;
    } on TimeoutException {
      throw ApiException('Koneksi ke server terlalu lama. Silakan coba lagi.');
    } on http.ClientException {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan API Laravel sudah berjalan.',
      );
    }
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> delete(String path) {
    return _send('DELETE', path);
  }

  /// Kirim multipart (dipakai untuk upload banner event).
  ///
  /// Catatan: PHP tidak mem-parsing multipart untuk PUT, jadi method lain
  /// dikirim sebagai POST + `_method` (method spoofing Laravel).
  Future<dynamic> multipart(
    String method,
    String path, {
    required Map<String, String> fields,
    XFile? file,
    String fileField = 'banner',
    List<XFile>? files,
    Map<String, XFile>? namedFiles,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';

    final token = await AppStorage.readToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final data = Map<String, String>.from(fields);
    if (method != 'POST') {
      data['_method'] = method;
    }
    request.fields.addAll(data);

    if (file != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          await file.readAsBytes(),
          filename: file.name,
        ),
      );
    }

    if (files != null) {
      for (final item in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            '$fileField[]',
            await item.readAsBytes(),
            filename: item.name,
          ),
        );
      }
    }

    if (namedFiles != null) {
      for (final entry in namedFiles.entries) {
        request.files.add(
          http.MultipartFile.fromBytes(
            entry.key,
            await entry.value.readAsBytes(),
            filename: entry.value.name,
          ),
        );
      }
    }

    try {
      final streamed = await _client
          .send(request)
          .timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);

      return _handle(response, didSendAuth: true, path: path);
    } on TimeoutException {
      throw ApiException('Koneksi ke server terlalu lama. Silakan coba lagi.');
    } on http.ClientException {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan API Laravel sudah berjalan.',
      );
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
  }) async {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value.isNotEmpty) {
        params[key] = value;
      }
    });

    final uri = Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: params.isEmpty ? null : params);

    final headers = <String, String>{'Accept': 'application/json'};

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (auth) {
      final token = await AppStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      late http.Response response;

      switch (method) {
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(ApiConfig.requestTimeout);
        case 'PUT':
          response = await _client
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(ApiConfig.requestTimeout);
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(ApiConfig.requestTimeout);
        default:
          response = await _client
              .get(uri, headers: headers)
              .timeout(ApiConfig.requestTimeout);
      }

      return _handle(response, didSendAuth: auth, path: path);
    } on TimeoutException {
      throw ApiException('Koneksi ke server terlalu lama. Silakan coba lagi.');
    } on http.ClientException {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan API Laravel sudah berjalan.',
      );
    }
  }

  dynamic _handle(
    http.Response response, {
    required bool didSendAuth,
    required String path,
  }) {
    dynamic decoded;

    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw ApiException('Respons server tidak dapat dibaca.');
      }
    }

    final map = decoded is Map<String, dynamic> ? decoded : null;

    if (response.statusCode == 401 && didSendAuth && path != '/login') {
      unawaited(onUnauthorized?.call());
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (isSuccess) {
      if (map != null && map.containsKey('data')) {
        return map['data'];
      }

      return decoded;
    }

    final message = map?['message']?.toString().trim();

    throw ApiException(
      message == null || message.isEmpty
          ? 'Terjadi kesalahan. Silakan coba lagi.'
          : message,
      statusCode: response.statusCode,
      errors: _parseErrors(map?['errors']),
    );
  }

  Map<String, List<String>> _parseErrors(dynamic raw) {
    final result = <String, List<String>>{};

    if (raw is! Map) {
      return result;
    }

    raw.forEach((key, value) {
      if (value is List) {
        result[key.toString()] = value.map((item) => item.toString()).toList();
      } else if (value != null) {
        result[key.toString()] = [value.toString()];
      }
    });

    return result;
  }
}
