import 'dart:async';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

/// OpenDART API client.
///
/// Handles authentication, HTTP requests, and response parsing
/// for the FSS (Financial Supervisory Service) Open DART system.
class OpenDartClient {
  static const String _baseUrl = 'https://opendart.fss.or.kr/api';

  final String apiKey;
  final http.Client _httpClient;
  final Duration timeout;
  final int maxRequestsPerDay;

  final List<DateTime> _requestTimestamps = [];

  OpenDartClient({
    required this.apiKey,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
    this.maxRequestsPerDay = 10000,
  }) : _httpClient = httpClient ?? http.Client();

  /// Returns the current request count in the sliding 24-hour window.
  @visibleForTesting
  int get requestCount {
    _cleanupOldTimestamps();
    return _requestTimestamps.length;
  }

  /// Removes timestamps older than 24 hours from the tracking list.
  void _cleanupOldTimestamps() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    _requestTimestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }

  /// Checks rate limit and throws if exceeded.
  void _checkRateLimit() {
    _cleanupOldTimestamps();
    if (_requestTimestamps.length >= maxRequestsPerDay) {
      throw const OpenDartException(
        '요청 제한을 초과했습니다',
        dartStatus: '020',
      );
    }
  }

  /// Records a new request timestamp.
  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  /// Performs a GET request to the OpenDART API.
  ///
  /// Returns parsed JSON response as a Map.
  /// Throws [OpenDartException] on API errors.
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    _checkRateLimit();

    final queryParams = {
      'crtfc_key': apiKey,
      ...?params,
    };

    final uri = Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _httpClient.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(timeout);

      _recordRequest();

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
    } on TimeoutException {
      throw OpenDartException(
        'Request timeout after ${timeout.inSeconds} seconds',
      );
    }
  }

  /// Downloads raw bytes from the OpenDART API (for XML/ZIP endpoints).
  Future<List<int>> getBytes(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    _checkRateLimit();

    final queryParams = {
      'crtfc_key': apiKey,
      ...?params,
    };

    final uri = Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _httpClient.get(uri).timeout(timeout);

      _recordRequest();

      if (response.statusCode != 200) {
        throw OpenDartException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }

      return response.bodyBytes;
    } on TimeoutException {
      throw OpenDartException(
        'Request timeout after ${timeout.inSeconds} seconds',
      );
    }
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

  // ─── Corp Code Cache (corpCode.xml) ──────────────────────

  List<CorpInfo>? _corpCodeCache;

  /// Downloads and caches the full corporate code list from corpCode.xml.
  ///
  /// The list is lazily loaded on first call and cached in memory.
  /// Call [clearCorpCodeCache] to force a refresh.
  Future<List<CorpInfo>> getCorpCodes() async {
    if (_corpCodeCache != null) return _corpCodeCache!;

    final bytes = await getBytes('corpCode.xml');
    final archive = ZipDecoder().decodeBytes(bytes);

    final xmlFile = archive.files.firstWhere(
      (f) => f.name.toUpperCase().endsWith('.XML'),
      orElse: () => throw const OpenDartException(
        'corpCode.xml ZIP에서 XML 파일을 찾을 수 없습니다',
      ),
    );

    final xmlContent = utf8.decode(xmlFile.content as List<int>);
    final document = XmlDocument.parse(xmlContent);

    final items = document.findAllElements('list');
    final result = <CorpInfo>[];

    for (final item in items) {
      final corpCode = item.getElement('corp_code')?.innerText ?? '';
      final corpName = item.getElement('corp_name')?.innerText ?? '';
      if (corpCode.isEmpty || corpName.isEmpty) continue;

      result.add(CorpInfo(
        corpCode: corpCode,
        corpName: corpName,
        corpEngName: item.getElement('corp_eng_name')?.innerText,
        stockCode: item.getElement('stock_code')?.innerText,
        modifyDate: item.getElement('modify_date')?.innerText,
      ));
    }

    _corpCodeCache = result;
    return result;
  }

  /// Searches the cached corporate code list by company name.
  ///
  /// Performs case-insensitive substring matching on Korean and English names.
  Future<List<CorpInfo>> searchCorpCode(String name) async {
    final corps = await getCorpCodes();
    final query = name.toLowerCase();

    return corps.where((c) {
      if (c.corpName.toLowerCase().contains(query)) return true;
      if (c.corpEngName != null &&
          c.corpEngName!.toLowerCase().contains(query)) return true;
      return false;
    }).toList();
  }

  /// Clears the cached corporate code list, forcing a fresh download
  /// on the next call to [getCorpCodes] or [searchCorpCode].
  void clearCorpCodeCache() {
    _corpCodeCache = null;
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

/// Corporate information from the corpCode.xml master list.
class CorpInfo {
  final String corpCode;
  final String corpName;
  final String? corpEngName;
  final String? stockCode;
  final String? modifyDate;

  const CorpInfo({
    required this.corpCode,
    required this.corpName,
    this.corpEngName,
    this.stockCode,
    this.modifyDate,
  });

  /// Whether this company is listed on a stock exchange.
  bool get isListed => stockCode != null && stockCode!.trim().isNotEmpty;
}
