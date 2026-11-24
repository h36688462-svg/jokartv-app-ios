import '../models/iptv_models.dart';
import '../services/storage_service.dart';

class PlaybackDatabase {
  static Future<int> getProgress(String streamId) async {
    return await StorageService.getProgress(streamId);
  }

  static Future<void> saveProgress(String streamId, int positionMs) async {
    await StorageService.saveProgress(streamId, positionMs);
  }

  static Future<List<StreamItem>> getHistory() async {
    return await StorageService.getHistory();
  }

  static Future<void> addToHistory(StreamItem item) async {
    await StorageService.addToHistory(item);
  }

  static Future<List<String>> getFavorites() async {
    return await StorageService.getFavorites();
  }

  static Future<void> toggleFavorite(String streamId) async {
    await StorageService.toggleFavorite(streamId);
  }

  static Future<List<String>> getWatchedEpisodes(String seriesId) async {
    return await StorageService.getWatchedEpisodes(seriesId);
  }

  static Future<void> toggleWatchedEpisode(String seriesId, String episodeId) async {
    await StorageService.toggleWatchedEpisode(seriesId, episodeId);
  }
}
