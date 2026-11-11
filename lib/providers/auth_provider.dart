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
      final res = await IptvApiClient.verifyActivationCode(savedCode);
      if (res != null && res.containsKey('user_info') && res['user_info'] is Map<String, dynamic>) {
        _userInfo = res['user_info'] as Map<String, dynamic>;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await IptvApiClient.verifyActivationCode(code);
    _isLoading = false;

    if (result != null && result.containsKey('user_info')) {
      _activeCode = code;
      _isLoggedIn = true;
      if (result['user_info'] is Map<String, dynamic>) {
        _userInfo = result['user_info'] as Map<String, dynamic>;
      }
      await StorageService.saveActivationCode(code);
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Invalid activation code or server connection failed.';
      notifyListeners();
      return false;
    }
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
