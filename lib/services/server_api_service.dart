import 'dart:convert';

import 'package:http/http.dart' as http;

import 'apk_access_contract.dart';

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

  Future<List<ApkAccessGrant>> getApkAccessGrants() async {
    final response =
        await _get('/api/v1/scada/apk-access/grants');

    final raw = response['data'];

    if (raw is! List) {
      throw const FormatException(
        'Invalid APK access grants response',
      );
    }

    return raw
        .whereType<Map>()
        .map(
          (item) => ApkAccessGrant.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  Future<List<ServerMessage>> getMunicipalMessages() async {
    final response = await _get('/api/v1/municipal/messages');
    final raw = response['data'];
    if (raw is! List) {
      throw const FormatException('Invalid municipal messages response');
    }
    return raw.whereType<Map>()
        .map((item) => ServerMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> markMunicipalMessageRead(String messageId) async {
    await _post('/api/v1/municipal/messages/$messageId/read', const {});
  }

  Future<void> acknowledgeMunicipalMessage(String messageId) async {
    await _post('/api/v1/municipal/messages/$messageId/acknowledge', const {});
  }

  Future<List<Map<String, dynamic>>> getRegisteredMunicipalValves() async {
    final response = await _get('/api/v1/municipal/valves/registered');
    final raw = response['data'];
    if (raw is! List) {
      throw const FormatException('Invalid registered valves response');
    }
    return raw.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
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

  Future<Map<String, dynamic>> requestMunicipalOtp({
    required String phone,
  }) {
    return _post(
      '/api/v1/municipal/auth/request-otp',
      {'phone': phone},
    );
  }

  Future<Map<String, dynamic>> verifyMunicipalOtp({
    required String phone,
    required String otp,
  }) {
    return _post(
      '/api/v1/municipal/auth/verify-otp',
      {'phone': phone, 'otp': otp},
    );
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

class ServerMessage {
  final String id, title, message, type, priority;
  final DateTime? createdAt, activeUntil;
  final bool isRead, isAcknowledged;

  const ServerMessage({
    required this.id, required this.title, required this.message,
    required this.type, required this.priority, required this.createdAt,
    required this.activeUntil, required this.isRead, required this.isAcknowledged,
  });

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    return ServerMessage(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'GENERAL').toString(),
      priority: (json['priority'] ?? 'NORMAL').toString(),
      createdAt: parseDate(json['created_at']),
      activeUntil: parseDate(json['active_until']),
      isRead: json['is_read'] == true,
      isAcknowledged: json['is_acknowledged'] == true,
    );
  }
}

class ServerApiException implements Exception {
  final int statusCode;
  final Map<String, dynamic> body;

  const ServerApiException(this.statusCode, this.body);

  @override
  String toString() => 'Server API error ($statusCode): $body';
}
