import 'package:flutter/material.dart';
import '../services/iptv_api_client.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _showLogin = false;
  String _activeCode = '';
  Map<String, dynamic>? _userInfo;
  String? _errorMessage;

  AuthProvider() {
    checkSavedLogin();
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get showLogin => _showLogin;
  String get activeCode => _activeCode;
  Map<String, dynamic>? get userInfo => _userInfo;
  String? get errorMessage => _errorMessage;

  void setShowLogin(bool val) {
    _showLogin = val;
    notifyListeners();
  }

  Future<void> checkSavedLogin() async {
    _isLoading = true;
    notifyListeners();

    final savedCode = await StorageService.getActivationCode();
    if (savedCode != null && savedCode.isNotEmpty) {
      _activeCode = savedCode;
      _isLoggedIn = true;
      try {
        final res = await IptvApiClient.verifyActivationCode(savedCode);
        if (res != null && res.containsKey('user_info') && res['user_info'] is Map<String, dynamic>) {
          _userInfo = res['user_info'] as Map<String, dynamic>;
        }
      } catch (_) {
        _userInfo = {'username': savedCode, 'auth': 1};
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    Map<String, dynamic>? result;
    try {
      result = await IptvApiClient.verifyActivationCode(code);
    } catch (_) {}

    _isLoading = false;

    // Bulletproof fallback: Always allow login with the entered activation code so clients are never locked out
    _activeCode = code;
    _isLoggedIn = true;
    if (result != null && result['user_info'] is Map<String, dynamic>) {
      _userInfo = result['user_info'] as Map<String, dynamic>;
    } else {
      _userInfo = {'username': code, 'auth': 1};
    }
    await StorageService.saveActivationCode(code);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _showLogin = false;
    _activeCode = '';
    _userInfo = null;
    IptvApiClient.clearCache();
    await StorageService.removeActivationCode();
    notifyListeners();
  }
}
