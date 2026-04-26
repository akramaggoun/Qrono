import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../core/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  final _notifService = NotificationService();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _userRole;
  String? _userName;
  String? _userId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;
  String? get userName => _userName;
  String? get userId => _userId;

  Future<bool> login(String matricule, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? fcmToken = await _notifService.getToken();

      final response = await _apiClient.post('/auth/login', {
        'email': matricule, // Backend expects 'email'
        'password': password,
        'fcmToken': fcmToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📥 LOGIN RESPONSE: $data');
        final token = data['token'];
        final role = data['user']?['role']?.toString().toLowerCase(); // Bug 2: Normalize
        final name = data['user']?['name'] ?? 'Utilisateur';

        // Cache token in memory immediately for instant use
        await TokenStorage.saveToken(token);
        await TokenStorage.saveRole(role ?? '');
        await TokenStorage.saveName(name);

        debugPrint('✅ LOGIN SUCCESS - Token: $token');
        debugPrint('✅ Role saved: $role');

        _userRole = role;
        _userName = name;
        _userId = data['user']?['id']?.toString();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 404) {
        _errorMessage = 'Compte non trouvé.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Identifiants incorrects.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (response.statusCode == 403) {
        _errorMessage = 'Votre compte est désactivé.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Échec de la connexion.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur réseau.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout', {});
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    await TokenStorage.clearAuthData();
    _userRole = null;
    notifyListeners();
  }
}

