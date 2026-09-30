import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CustomerSession {
  static const _customerIdKey = 'customer_id';
  static const _phoneKey = 'customer_phone';

  static const serverBaseUrl = String.fromEnvironment(
    'ORB_SERVER_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static Future<Map<String, dynamic>?> loginByPhone(String phone) async {
    final response = await http.post(
      Uri.parse('$serverBaseUrl/api/v1/customer/session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone.trim()}),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerIdKey, data['customer_id'].toString());
    await prefs.setString(_phoneKey, data['phone'].toString());
    return data;
  }

  static Future<String?> customerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customerIdKey);
  }
}
