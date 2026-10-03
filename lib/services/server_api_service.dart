import 'dart:convert';

import 'package:http/http.dart' as http;

class ServerApiService {
  final String baseUrl;
  String? bearerToken;

  ServerApiService({
    required this.baseUrl,
    this.bearerToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (bearerToken != null && bearerToken!.isNotEmpty)
          'Authorization': 'Bearer $bearerToken',
      };

  Future<List<ApkAccessGrant>> listApkAccessGrants() async {
    final response = await _get('/api/v1/scada/apk-access/grants');
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => ApkAccessGrant.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }
    return const [];
  }

  Future<ApkAccessGrant> upsertApkAccessGrant({
    required String phone,
    required String ward,
    required List<String> zones,
    required List<String> valves,
    bool enabled = true,
  }) async {
    final response = await _post(
      '/api/v1/scada/apk-access/grants',
      {
        'phone': phone,
        'ward': ward,
        'zones': zones,
        'valves': valves,
        'enabled': enabled,
      },
    );
    return ApkAccessGrant.fromJson(response);
  }

  Future<void> setApkAccessEnabled({
    required String grantId,
    required bool enabled,
  }) async {
    final encoded = Uri.encodeComponent(grantId);
    await _patch(
      '/api/v1/scada/apk-access/grants/$encoded/enabled?enabled=$enabled',
    );
  }

  Future<void> deleteApkAccessGrant(String grantId) async {
    final encoded = Uri.encodeComponent(grantId);
    await _delete('/api/v1/scada/apk-access/grants/$encoded');
  }

  Future<Map<String, dynamic>> registerValveById({
    required String valveId,
    required String wardId,
    required String zoneId,
    required double latitude,
    required double longitude,
  }) {
    return _post(
      '/api/v1/municipal/valves/register-by-valve-id',
      {
        'valve_id': valveId,
        'ward_id': wardId,
        'zone_id': zoneId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<Map<String, dynamic>> getBillingSummary({
    required DateTime periodStart,
    required DateTime periodEnd,
    double usdInr = 90.0,
  }) {
    final query = Uri(queryParameters: {
      'period_start': _date(periodStart),
      'period_end': _date(periodEnd),
      'usd_inr': usdInr.toString(),
    }).query;
    return _get('/api/v1/municipal/billing/summary?$query');
  }

  Future<Map<String, dynamic>> getValveOperatingCost({
    required String valveId,
    required DateTime periodStart,
    required DateTime periodEnd,
    double usdInr = 90.0,
  }) {
    final query = Uri(queryParameters: {
      'period_start': _date(periodStart),
      'period_end': _date(periodEnd),
      'usd_inr': usdInr.toString(),
    }).query;
    return _get('/api/v1/municipal/billing/valves/$valveId?$query');
  }

  Future<Map<String, dynamic>> getFinanceSummary({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final query = Uri(queryParameters: {
      'period_start': _date(periodStart),
      'period_end': _date(periodEnd),
    }).query;
    return _get('/api/v1/municipal/finance/summary?$query');
  }

  Future<Map<String, dynamic>> getBillingPreview({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final query = Uri(queryParameters: {
      'period_start': _date(periodStart),
      'period_end': _date(periodEnd),
    }).query;
    return _get('/api/v1/municipal/finance/billing-preview?$query');
  }

  Future<Map<String, dynamic>> createPayment({
    required String receiptNumber,
    required double amount,
    required DateTime paymentDate,
    String method = 'OTHER',
    String? invoiceId,
    String? valveId,
    String? wardId,
    String? zoneId,
  }) {
    return _post(
      '/api/v1/municipal/finance/payments',
      {
        'receipt_number': receiptNumber,
        'amount': amount,
        'payment_date': _date(paymentDate),
        'method': method,
        if (invoiceId != null) 'invoice_id': invoiceId,
        if (valveId != null) 'valve_id': valveId,
        if (wardId != null) 'ward_id': wardId,
        if (zoneId != null) 'zone_id': zoneId,
      },
    );
  }

  Future<Map<String, dynamic>> createInvoice({
    required String invoiceNumber,
    required double amount,
    required DateTime invoiceDate,
    DateTime? dueDate,
    String? valveId,
    String? wardId,
    String? zoneId,
    String? description,
  }) {
    return _post(
      '/api/v1/municipal/finance/invoices',
      {
        'invoice_number': invoiceNumber,
        'amount': amount,
        'invoice_date': _date(invoiceDate),
        if (dueDate != null) 'due_date': _date(dueDate),
        if (valveId != null) 'valve_id': valveId,
        if (wardId != null) 'ward_id': wardId,
        if (zoneId != null) 'zone_id': zoneId,
        if (description != null) 'description': description,
      },
    );
  }

  Future<Map<String, dynamic>> _patch(String path) async {
    final response = await http.patch(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(response);
  }

  Future<void> _delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = {'raw': response.body};
      }
      throw ServerApiException(
        response.statusCode,
        decoded is Map<String, dynamic> ? decoded : {'body': decoded},
      );
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {'raw': response.body};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerApiException(
        response.statusCode,
        decoded is Map<String, dynamic> ? decoded : {'body': decoded},
      );
    }
    return decoded is Map<String, dynamic>
        ? decoded
        : {'data': decoded};
  }

  String _date(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class ServerApiException implements Exception {
  final int statusCode;
  final Map<String, dynamic> body;

  const ServerApiException(this.statusCode, this.body);

  @override
  String toString() => 'Server API error ($statusCode): $body';
}
