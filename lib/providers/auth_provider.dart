import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://'))) {
      _errorMessage = 'Please enter a valid HTTP/HTTPS M3U URL';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(cleanUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || (!response.body.contains('#EXTM3U') && !response.body.contains('#EXTINF'))) {
        _errorMessage = 'Invalid or unreachable M3U playlist';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Failed to connect to M3U playlist URL';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    await StorageService.saveMediaSource(
      type: 'm3u',
      name: name.trim().isEmpty ? 'My M3U Playlist' : name.trim(),
      url: cleanUrl,
    );

    _sourceInfo = await StorageService.getMediaSource();
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> loginWithServer(String name, String serverUrl, String username, String password) async {
    final cleanHost = serverUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanUser = username.trim();
    final cleanPass = password.trim();

    if (cleanHost.isEmpty || cleanUser.isEmpty || cleanPass.isEmpty) {
      _errorMessage = 'Please fill in all server login fields';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiUri = Uri.parse('$cleanHost/player_api.php?username=$cleanUser&password=$cleanPass');
      final response = await http.get(apiUri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final userInfo = decoded['user_info'];
          if (userInfo is Map<String, dynamic> && userInfo['auth'] == 0) {
            _errorMessage = 'Server authentication failed (Invalid credentials)';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          _errorMessage = 'Invalid server response';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Server returned error status: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Unable to connect to server URL';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    await StorageService.saveMediaSource(
      type: 'server',
      name: name.trim().isEmpty ? 'Media Server' : name.trim(),
      url: cleanHost,
      username: cleanUser,
      password: cleanPass,
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
