import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  Future<Map<String, String>> get _headers async {
    final token = await TokenStorage.getToken();
    print('🔑 SENDING TOKEN: $token');
    
    if (token == null) {
      print('❌ TOKEN IS NULL — User not logged in!');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'bypass-tunnel-reminder': 'true',
    };
  }

  Future<http.Response> get(String path) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConstants.baseUrl}$path';
    final token = headers['Authorization'];

    print('🌐 [QRONO NET] GET -> $url');
    print('🔑 AUTH TOKEN: ${token?.substring(0, 10)}...');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      print('✅ [QRONO NET] STATUS: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ [QRONO NET ERROR] GET FAILED: $e');
      rethrow;
    }
  }

  Future<http.Response> post(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConstants.baseUrl}$path';
    final token = headers['Authorization'];

    print('🌐 [QRONO NET] POST -> $url');
    print('📦 BODY: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: headers,
      );
      print('✅ [QRONO NET] STATUS: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ [QRONO NET ERROR] POST FAILED: $e');
      rethrow;
    }
  }

  Future<http.Response> put(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConstants.baseUrl}$path';
    
    print('🌐 REQUEST: PUT $url');
    print('📦 BODY: $body');
    
    final response = await http.put(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
    print('✅ RESPONSE ${response.statusCode}: ${response.body}');
    return response;
  }

  Future<http.Response> patch(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConstants.baseUrl}$path';
    
    print('🌐 REQUEST: PATCH $url');
    
    final response = await http.patch(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
    print('✅ RESPONSE ${response.statusCode}: ${response.body}');
    return response;
  }

  Future<http.Response> delete(String path) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : '${ApiConstants.baseUrl}$path';
    
    print('🌐 REQUEST: DELETE $url');
    
    final response = await http.delete(Uri.parse(url), headers: headers);
    print('✅ RESPONSE ${response.statusCode}: ${response.body}');
    return response;
  }
}
