import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenDART API client.
///
/// Handles authentication, HTTP requests, and response parsing
/// for the FSS (Financial Supervisory Service) Open DART system.
class OpenDartClient {
  static const String _baseUrl = 'https://opendart.fss.or.kr/api';

  final String apiKey;
  final http.Client _httpClient;

  OpenDartClient({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Performs a GET request to the OpenDART API.
  ///
  /// Returns parsed JSON response as a Map.
  /// Throws [OpenDartException] on API errors.
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final queryParams = {
      'crtfc_key': apiKey,
      ...?params,
    };

    final uri = Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: queryParams,
    );

    final response = await _httpClient.get(uri, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw OpenDartException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // OpenDART uses status/message pattern for errors
    final status = body['status'] as String?;
    if (status != null && status != '000') {
      throw OpenDartException(
        _statusMessage(status, body['message'] as String?),
        statusCode: response.statusCode,
        dartStatus: status,
      );
    }

    return body;
  }

  /// Downloads raw bytes from the OpenDART API (for XML/ZIP endpoints).
  Future<List<int>> getBytes(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final queryParams = {
      'crtfc_key': apiKey,
      ...?params,
    };

    final uri = Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: queryParams,
    );

    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw OpenDartException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }

    return response.bodyBytes;
  }

  String _statusMessage(String status, String? message) {
    final descriptions = {
      '010': '등록되지 않은 키입니다',
      '011': '사용할 수 없는 키입니다',
      '012': '접근할 수 없는 IP입니다',
      '013': '조회된 데이터가 없습니다',
      '014': '파일이 존재하지 않습니다',
      '020': '요청 제한을 초과했습니다',
      '100': '필드의 부적절한 값입니다',
      '800': '시스템 점검 중입니다',
      '900': '정의되지 않은 오류가 발생했습니다',
    };

    return message ?? descriptions[status] ?? '알 수 없는 오류 (status: $status)';
  }

  void close() {
    _httpClient.close();
  }
}

/// Exception thrown by OpenDART API operations.
class OpenDartException implements Exception {
  final String message;
  final int? statusCode;
  final String? dartStatus;

  const OpenDartException(
    this.message, {
    this.statusCode,
    this.dartStatus,
  });

  @override
  String toString() => 'OpenDartException: $message';
}
