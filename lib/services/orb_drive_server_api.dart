import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/municipal_billing.dart';

class OrbDriveServerApi {
  OrbDriveServerApi({required this.baseUrl, this.authorizationToken, http.Client? client}) : _client = client ?? http.Client();
  final String baseUrl;
  final String? authorizationToken;
  final http.Client _client;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (authorizationToken != null && authorizationToken!.isNotEmpty) 'Authorization': authorizationToken!,
  };

  Uri _uri(String path, Map<String, String> query) {
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse(root + path).replace(queryParameters: query);
  }

  Future<MunicipalBillingSummary> getBillingSummary({required DateTime periodStart, required DateTime periodEnd, double usdInr = 90}) async {
    final response = await _client.get(_uri('/api/v1/municipal/billing/summary', {
      'period_start': _date(periodStart), 'period_end': _date(periodEnd), 'usd_inr': usdInr.toString(),
    }), headers: _headers);
    return _decode(response, MunicipalBillingSummary.fromJson);
  }

  Future<Map<String, dynamic>> getValveBilling({required String valveId, required DateTime periodStart, required DateTime periodEnd, double usdInr = 90}) async {
    final response = await _client.get(_uri('/api/v1/municipal/billing/valves/' + valveId, {
      'period_start': _date(periodStart), 'period_end': _date(periodEnd), 'usd_inr': usdInr.toString(),
    }), headers: _headers);
    return _decode(response, (json) => json);
  }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  T _decode<T>(http.Response response, T Function(Map<String, dynamic>) parser) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['detail'] != null ? decoded['detail'].toString() : 'Server request failed (${response.statusCode})';
      throw Exception(message);
    }
    if (decoded is! Map) throw const FormatException('Server response is not an object');
    return parser(Map<String, dynamic>.from(decoded));
  }

  void dispose() => _client.close();
}