import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/iptv_models.dart';

class IptvApiClient {
  static const String defaultHost = 'http://169.58.114.30:8080';

  // Cache
  static List<CategoryItem>? liveCategoriesCache;
  static List<CategoryItem>? vodCategoriesCache;
  static List<CategoryItem>? seriesCategoriesCache;

  static List<StreamItem>? liveStreamsCache;
  static List<StreamItem>? vodStreamsCache;
  static List<StreamItem>? seriesStreamsCache;

  static void clearCache() {
    liveCategoriesCache = null;
    vodCategoriesCache = null;
    seriesCategoriesCache = null;
    liveStreamsCache = null;
    vodStreamsCache = null;
    seriesStreamsCache = null;
  }

  static Future<Map<String, dynamic>?> verifyActivationCode(String code, {String? host}) async {
    final h = host ?? defaultHost;
    try {
      final url = Uri.parse('$h/player_api.php?username=$code&password=$code');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<CategoryItem>> getCategories(
    String code,
    String action, {
    String? host,
    bool useCache = true,
  }) async {
    final h = host ?? defaultHost;
    if (useCache) {
      if (action == 'get_live_categories' && liveCategoriesCache != null) return liveCategoriesCache!;
      if (action == 'get_vod_categories' && vodCategoriesCache != null) return vodCategoriesCache!;
      if (action == 'get_series_categories' && seriesCategoriesCache != null) return seriesCategoriesCache!;
    }

    try {
      final url = Uri.parse('$h/player_api.php?username=$code&password=$code&action=$action');
      final response = await http.get(url).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final categories = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => CategoryItem.fromJson(e))
              .toList();
          if (action == 'get_live_categories') liveCategoriesCache = categories;
          if (action == 'get_vod_categories') vodCategoriesCache = categories;
          if (action == 'get_series_categories') seriesCategoriesCache = categories;
          return categories;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<StreamItem>> getStreams(
    String code,
    String type,
    String categoryId, {
    String? host,
    bool useCache = true,
  }) async {
    final h = host ?? defaultHost;
    final isAllOrFavorites = categoryId.isEmpty || categoryId == 'favorites' || categoryId == 'all';
    if (useCache && isAllOrFavorites) {
      if (type == 'live' && liveStreamsCache != null) return liveStreamsCache!;
      if (type == 'movies' && vodStreamsCache != null) return vodStreamsCache!;
      if (type == 'series' && seriesStreamsCache != null) return seriesStreamsCache!;
    }

    String action;
    switch (type) {
      case 'live':
        action = 'get_live_streams';
      case 'movies':
        action = 'get_vod_streams';
      case 'series':
        action = 'get_series';
      default:
        action = 'get_live_streams';
    }

    var urlStr = '$h/player_api.php?username=$code&password=$code&action=$action';
    if (categoryId.isNotEmpty && categoryId != 'favorites' && categoryId != 'all') {
      urlStr += '&category_id=$categoryId';
    }

    try {
      final url = Uri.parse(urlStr);
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final streams = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => StreamItem.fromJson(e, type))
              .toList();

          if (isAllOrFavorites) {
            if (type == 'live') liveStreamsCache = streams;
            if (type == 'movies') vodStreamsCache = streams;
            if (type == 'series') seriesStreamsCache = streams;
          }

          if (categoryId.isNotEmpty && categoryId != 'favorites' && categoryId != 'all') {
            return streams.where((s) => s.categoryId == categoryId).toList();
          }
          return streams;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<SeriesDetails?> getSeriesInfo(String code, String seriesId, {String? host}) async {
    final h = host ?? defaultHost;
    try {
      final url = Uri.parse('$h/player_api.php?username=$code&password=$code&action=get_series_info&series_id=$seriesId');
      final response = await http.get(url).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return SeriesDetails.fromJson(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<VodDetails?> getVodInfo(String code, String vodId, {String? host}) async {
    final h = host ?? defaultHost;
    try {
      final url = Uri.parse('$h/player_api.php?username=$code&password=$code&action=get_vod_info&vod_id=$vodId');
      final response = await http.get(url).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return VodDetails.fromJson(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  static String getStreamUrl(String code, String type, String streamId, {String? extension, String? host}) {
    final h = host ?? defaultHost;
    final ext = (extension != null && extension.isNotEmpty) ? extension : 'mp4';
    switch (type) {
      case 'live':
        return '$h/live/$code/$code/$streamId';
      case 'movies':
        return '$h/movie/$code/$code/$streamId.$ext';
      case 'series':
        return '$h/series/$code/$code/$streamId.$ext';
      default:
        return '$h/live/$code/$code/$streamId';
    }
  }
}
