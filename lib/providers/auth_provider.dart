import 'package:flutter/material.dart';
import '../services/iptv_api_client.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  Map<String, String>? _sourceInfo;
  String? _errorMessage;

  AuthProvider() {
    checkSavedLogin();
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  Map<String, String>? get sourceInfo => _sourceInfo;
  String get activeCode => _sourceInfo?['username'] ?? _sourceInfo?['url'] ?? '';
  Map<String, dynamic>? get userInfo => {
        'username': _sourceInfo?['name'] ?? 'Personal Media Source',
        'auth': 1,
      };
  String? get errorMessage => _errorMessage;

  Future<void> checkSavedLogin() async {
    _isLoading = true;
    notifyListeners();

    final source = await StorageService.getMediaSource();
    if (source != null && source['url'] != null && source['url']!.isNotEmpty) {
      _sourceInfo = source;
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithM3U(String name, String url) async {
    if (url.trim().isEmpty) {
      _errorMessage = 'Please enter a valid M3U URL';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await StorageService.saveMediaSource(
      type: 'm3u',
      name: name.trim().isEmpty ? 'My M3U Playlist' : name.trim(),
      url: url.trim(),
    );

    _sourceInfo = await StorageService.getMediaSource();
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> loginWithServer(String name, String serverUrl, String username, String password) async {
    if (serverUrl.trim().isEmpty || username.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Please fill in all server login fields';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await StorageService.saveMediaSource(
      type: 'server',
      name: name.trim().isEmpty ? 'Media Server' : name.trim(),
      url: serverUrl.trim(),
      username: username.trim(),
      password: password.trim(),
    );

    _sourceInfo = await StorageService.getMediaSource();
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }



  Future<void> logout() async {
    _isLoggedIn = false;
    _sourceInfo = null;
    IptvApiClient.clearCache();
    await StorageService.clearMediaSource();
    notifyListeners();
  }
}
