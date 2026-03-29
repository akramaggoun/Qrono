import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  final _tokenStorage = TokenStorage();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _userRole;
  String? _userName;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;
  String? get userName => _userName;

  Future<bool> login(String matricule, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(ApiConstants.login, {
        'matricule': matricule,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role']; // ADMIN, PROFESSOR, STUDENT
        final name = data['user']?['name'] ?? 'Utilisateur';

        await _tokenStorage.saveToken(token);
        await _tokenStorage.saveRole(role);
        await _tokenStorage.saveName(name);
        _userRole = role;
        _userName = name;
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 404) {
        _errorMessage = 'Compte non trouvé.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Mot de passe incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (response.statusCode == 403) {
        _errorMessage = 'Votre compte est désactivé.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Échec de la connexion. Vérifiez vos identifiants.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Une erreur est survenue lors de la connexion.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearAuthData();
    _userRole = null;
    notifyListeners();
  }
}
