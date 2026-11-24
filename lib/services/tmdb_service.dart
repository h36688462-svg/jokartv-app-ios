import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TmdbService {
  static const String apiKey = 'ae616ebe1210c288be780354f6c0d3f9';
  static final Map<String, Map<String, dynamic>> _memoryCache = {};

  /// Normalize Arabic characters: unify (أ, إ, آ -> ا), (ة -> ه), (ى -> ي), remove diacritics
  static String normalizeArabic(String input) {
    String text = input;
    text = text.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    text = text.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    return text.toLowerCase().trim();
  }

  /// Clean title using regex and normalization
  static Map<String, String> cleanTitle(String rawName) {
    final yearMatch = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(rawName);
    final year = yearMatch != null ? yearMatch.group(0)! : '';

    String clean = rawName
        .replaceAll(RegExp(r'^(AR|EN|TR|FR|ES)\s*[:|\-]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(4K|UHD|1080p|720p|FHD|HD|WEB-DL|BluRay|HEVC|H264|H265|HDR)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?\]|\(.*?\)|\{.*?\}', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-–—|/]+'), ' ')
        .trim();

    if (year.isNotEmpty) {
      clean = clean.replaceAll(year, '').trim();
    }

    clean = normalizeArabic(clean);

    return {'cleanTitle': clean, 'year': year};
  }

  /// Search Movie or TV on TMDB with multi-language fallback strategy & local caching
  static Future<Map<String, dynamic>?> fetchMetadata(String rawTitle, String type) async {
    if (_memoryCache.containsKey(rawTitle)) {
      return _memoryCache[rawTitle];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('tmdb_$rawTitle');
      if (cachedJson != null) {
        final decoded = json.decode(cachedJson) as Map<String, dynamic>;
        _memoryCache[rawTitle] = decoded;
        return decoded;
      }
    } catch (_) {}

    try {
      final cleaned = cleanTitle(rawTitle);
      final query = cleaned['cleanTitle'] ?? '';
      final year = cleaned['year'] ?? '';

      if (query.isEmpty) return null;

      final endpoint = (type == 'series' || type == 'tv') ? 'tv' : 'movie';

      Map<String, dynamic>? result = await _executeSearch(endpoint, query, year);

      if (result == null && year.isNotEmpty) {
        result = await _executeSearch(endpoint, query, null);
      }

      if (result != null) {
        _memoryCache[rawTitle] = result;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('tmdb_$rawTitle', json.encode(result));
        } catch (_) {}
      }

      return result;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _executeSearch(String endpoint, String query, String? year) async {
    try {
      // Step 1: Search without language restriction first to find ID reliably for English/Arabic titles
      var url = 'https://api.themoviedb.org/3/search/$endpoint?api_key=$apiKey&query=${Uri.encodeComponent(query)}';
      if (year != null && year.isNotEmpty) {
        url += '&year=$year';
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final id = results.first['id'];
          // Step 2: Fetch rich Arabic details using the found ID
          return await fetchDetails(endpoint, id);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> fetchDetails(String endpoint, int id) async {
    try {
      final url = 'https://api.themoviedb.org/3/$endpoint/$id?api_key=$apiKey&append_to_response=credits,videos,images,recommendations&language=ar-SA';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static String getImageUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/$size$path';
  }

  static String? getYouTubeTrailerUrl(Map<String, dynamic>? details) {
    if (details == null) return null;
    final videos = details['videos']?['results'] as List?;
    if (videos == null || videos.isEmpty) return null;

    final trailer = videos.firstWhere(
      (v) => v['site'] == 'YouTube' && (v['type'] == 'Trailer' || v['type'] == 'Teaser'),
      orElse: () => videos.first,
    );

    final key = trailer?['key'];
    if (key != null) {
      return 'https://www.youtube.com/watch?v=$key';
    }
    return null;
  }

  static String? getClearLogo(Map<String, dynamic>? details) {
    if (details == null) return null;
    final logos = details['images']?['logos'] as List?;
    if (logos == null || logos.isEmpty) return null;

    final logoPath = logos.first['file_path']?.toString();
    if (logoPath != null) {
      return getImageUrl(logoPath, size: 'w500');
    }
    return null;
  }
}
