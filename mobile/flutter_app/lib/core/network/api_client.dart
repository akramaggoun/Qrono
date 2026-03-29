import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiClient {
  final _tokenStorage = TokenStorage();

  Future<Map<String, String>> get _headers async {
    final token = await _tokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : 'http://localhost:3000$path';
    return await http.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> post(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : 'http://localhost:3000$path';
    return await http.post(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
  }

  Future<http.Response> put(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : 'http://localhost:3000$path';
    return await http.put(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
  }

  Future<http.Response> patch(String path, dynamic body) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : 'http://localhost:3000$path';
    return await http.patch(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
  }

  Future<http.Response> delete(String path) async {
    final headers = await _headers;
    final url = path.startsWith('http') ? path : 'http://localhost:3000$path';
    return await http.delete(Uri.parse(url), headers: headers);
  }
}
