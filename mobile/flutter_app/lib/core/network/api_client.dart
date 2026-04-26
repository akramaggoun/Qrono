import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';
import '../config/api_config.dart';

class ApiClient {
  Future<Map<String, String>> get _headers async {
    final token = await TokenStorage.getToken();
    debugPrint('🔑 SENDING TOKEN: $token');
    
    if (token == null) {
      debugPrint('❌ TOKEN IS NULL — User not logged in!');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    final token = headers['Authorization'];

    debugPrint('🌐 REQUEST: GET $url');
    debugPrint('🔑 TOKEN: $token');

    final response = await http.get(Uri.parse(url), headers: headers);
    debugPrint('✅ RESPONSE ${response.statusCode}: ${response.body}');
    return response;
  }

  Future<http.Response> post(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    final token = headers['Authorization'];

    debugPrint('🌐 REQUEST: POST $url');
    debugPrint('📦 BODY: $body');
    debugPrint('🔑 TOKEN: $token');

    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
    
    debugPrint('✅ RESPONSE ${response.statusCode}: ${response.body}');
    return response;
  }

  Future<http.Response> put(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    
    debugPrint('🌐 REQUEST: PUT $url');
    debugPrint('📦 BODY: $body');
    
    final response = await http.put(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
    debugPrint('✅ RESPONSE ${response.statusCode}: ${response.body}');
    return response;
  }

  Future<http.Response> patch(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    
    debugPrint('🌐 REQUEST: PATCH $url');
    
    final response = await http.patch(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
    debugPrint('✅ RESPONSE ${response.statusCode}: ${response.body}');
    return response;
  }

  Future<http.Response> delete(String path) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    
    debugPrint('🌐 REQUEST: DELETE $url');
    
    final response = await http.delete(Uri.parse(url), headers: headers);
    debugPrint('✅ RESPONSE ${response.statusCode}: ${response.body}');
    return response;
  }
}
