import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/iptv_models.dart';

class StorageService {
  static const String keyFavorites = 'favorites_list';
  static const String keyAccounts = 'saved_accounts';
  static const String keyPin = 'parental_pin';
  static const String keyLockedCategories = 'locked_categories';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Media Source (BYOC)
  static Future<void> saveMediaSource({
    required String type,
    required String name,
    required String url,
    String? username,
    String? password,
    String? expDate,
    String? maxConnections,
    String? activeCons,
    String? status,
  }) async {
    final p = await prefs;
    await p.setString('source_type', type);
    await p.setString('source_name', name);
    await p.setString('source_url', url);
    await p.setString('source_username', username ?? '');
    await p.setString('source_password', password ?? '');
    await p.setString('source_exp_date', expDate ?? '');
    await p.setString('source_max_connections', maxConnections ?? '');
    await p.setString('source_active_cons', activeCons ?? '');
    await p.setString('source_status', status ?? '');
  }

  static Future<Map<String, String>?> getMediaSource() async {
    final p = await prefs;
    final type = p.getString('source_type');
    final url = p.getString('source_url');
    if ((type == null || type.isEmpty) && (url == null || url.isEmpty)) {
      return null;
    }
    return {
      'type': type ?? 'm3u',
      'name': p.getString('source_name') ?? 'Media Source',
      'url': url ?? '',
      'username': p.getString('source_username') ?? '',
      'password': p.getString('source_password') ?? '',
      'exp_date': p.getString('source_exp_date') ?? '',
      'max_connections': p.getString('source_max_connections') ?? '1',
      'active_cons': p.getString('source_active_cons') ?? '1',
      'status': p.getString('source_status') ?? 'Active',
    };
  }

  static Future<void> clearMediaSource() async {
    final p = await prefs;
    await p.remove('source_type');
    await p.remove('source_name');
    await p.remove('source_url');
    await p.remove('source_username');
    await p.remove('source_password');
    await p.remove('source_exp_date');
    await p.remove('source_max_connections');
    await p.remove('source_active_cons');
    await p.remove('source_status');
  }

  // Favorites
  static Future<List<String>> getFavorites() async {
    final p = await prefs;
    return p.getStringList(keyFavorites) ?? [];
  }

  static Future<bool> isFavorite(String streamId) async {
    final list = await getFavorites();
    return list.contains(streamId);
  }

  static Future<void> toggleFavorite(String streamId) async {
    final p = await prefs;
    final list = await getFavorites();
    if (list.contains(streamId)) {
      list.remove(streamId);
    } else {
      list.add(streamId);
    }
    await p.setStringList(keyFavorites, list);
  }

  // Watch Progress
  static Future<int> getProgress(String streamId) async {
    final p = await prefs;
    return p.getInt('progress_$streamId') ?? 0;
  }

  static Future<void> saveProgress(String streamId, int positionMs) async {
    final p = await prefs;
    await p.setInt('progress_$streamId', positionMs);
  }

  // Watch History
  static const String keyHistory = 'watch_history_items';

  static Future<List<StreamItem>> getHistory() async {
    final p = await prefs;
    final jsonStr = p.getString(keyHistory) ?? '[]';
    try {
      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => StreamItem.fromJson(e, e['streamType'] ?? 'movies'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addToHistory(StreamItem item) async {
    final p = await prefs;
    List<StreamItem> history = await getHistory();
    history.removeWhere((i) => i.streamId == item.streamId);
    history.insert(0, item);
    if (history.length > 20) {
      history = history.sublist(0, 20);
    }
    final encoded = json.encode(history.map((e) => e.toJson()).toList());
    await p.setString(keyHistory, encoded);
  }

  // Saved Accounts
  static Future<List<UserAccount>> getSavedAccounts() async {
    final p = await prefs;
    final jsonStr = p.getString(keyAccounts) ?? '[]';
    try {
      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => UserAccount.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addAccount(UserAccount account) async {
    final accounts = await getSavedAccounts();
    if (!accounts.any((acc) => acc.username == account.username && acc.url == account.url)) {
      accounts.add(account);
      final p = await prefs;
      await p.setString(keyAccounts, json.encode(accounts.map((e) => e.toJson()).toList()));
    }
  }

  static Future<void> removeAccount(String username) async {
    final accounts = await getSavedAccounts();
    accounts.removeWhere((acc) => acc.username == username);
    final p = await prefs;
    await p.setString(keyAccounts, json.encode(accounts.map((e) => e.toJson()).toList()));
  }

  // Parental Control
  static Future<String> getPin() async {
    final p = await prefs;
    return p.getString(keyPin) ?? '0000';
  }

  static Future<void> setPin(String newPin) async {
    final p = await prefs;
    await p.setString(keyPin, newPin);
  }

  static Future<List<String>> getLockedCategories() async {
    final p = await prefs;
    return p.getStringList(keyLockedCategories) ?? [];
  }

  static Future<bool> isCategoryLocked(String categoryName) async {
    final list = await getLockedCategories();
    return list.contains(categoryName);
  }

  static Future<void> toggleCategoryLock(String categoryName) async {
    final p = await prefs;
    final list = await getLockedCategories();
    if (list.contains(categoryName)) {
      list.remove(categoryName);
    } else {
      list.add(categoryName);
    }
    await p.setStringList(keyLockedCategories, list);
  }

  // Watched Episodes for Series
  static Future<List<String>> getWatchedEpisodes(String seriesId) async {
    final p = await prefs;
    return p.getStringList('watched_series_$seriesId') ?? [];
  }

  static Future<void> toggleWatchedEpisode(String seriesId, String episodeId) async {
    final p = await prefs;
    final list = await getWatchedEpisodes(seriesId);
    if (!list.contains(episodeId)) {
      list.add(episodeId);
      await p.setStringList('watched_series_$seriesId', list);
    }
  }
}
