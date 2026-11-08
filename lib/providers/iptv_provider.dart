import 'package:flutter/material.dart';
import '../models/iptv_models.dart';
import '../services/iptv_api_client.dart';
import '../services/storage_service.dart';

class IptvProvider extends ChangeNotifier {
  String _currentTab = 'movies';
  bool _isLoading = false;
  String? _error;
  List<DashboardCategory> _dashboardCategories = [];
  List<StreamItem> _categoryStreams = [];
  List<String> _favoriteIds = [];

  String get currentTab => _currentTab;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DashboardCategory> get dashboardCategories => _dashboardCategories;
  List<StreamItem> get categoryStreams => _categoryStreams;
  List<String> get favoriteIds => _favoriteIds;

  void setTab(String tab, String code) {
    if (_currentTab != tab) {
      _currentTab = tab;
      loadData(code);
    }
  }

  Future<void> loadFavorites() async {
    _favoriteIds = await StorageService.getFavorites();
    notifyListeners();
  }

  Future<void> loadData(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await loadFavorites();

    try {
      if (_currentTab == 'favorites') {
        await _loadFavoritesData(code);
      } else {
        await _loadCategoryData(code, _currentTab);
      }
    } catch (e) {
      _error = 'Failed to load content: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCategoryData(String code, String tab) async {
    String categoryAction;
    switch (tab) {
      case 'movies':
        categoryAction = 'get_vod_categories';
        break;
      case 'series':
        categoryAction = 'get_series_categories';
        break;
      case 'live':
        categoryAction = 'get_live_categories';
        break;
      default:
        categoryAction = 'get_vod_categories';
    }

    final categories = await IptvApiClient.getCategories(code, categoryAction);
    final allStreams = await IptvApiClient.getStreams(code, tab, '');

    Map<String, List<StreamItem>> grouped = {};
    for (var stream in allStreams) {
      String catId = stream.categoryId ?? 'uncategorized';
      grouped.putIfAbsent(catId, () => []).add(stream);
    }

    List<DashboardCategory> list = [];
    Set<String> processedCategoryIds = {};

    for (var cat in categories) {
      final items = grouped[cat.categoryId];
      if (items != null && items.isNotEmpty) {
        list.add(DashboardCategory(
          categoryId: cat.categoryId,
          categoryName: cat.categoryName,
          items: items,
        ));
        processedCategoryIds.add(cat.categoryId);
      }
    }

    // Collect any remaining/unmatched streams into an "Other" category
    List<StreamItem> remainingItems = [];
    grouped.forEach((catId, items) {
      if (!processedCategoryIds.contains(catId)) {
        remainingItems.addAll(items);
      }
    });

    if (remainingItems.isNotEmpty) {
      list.add(DashboardCategory(
        categoryId: 'other',
        categoryName: tab == 'live' ? 'Other Channels' : 'Other',
        items: remainingItems,
      ));
    }

    // For live tab, add an "All Channels" category at the very beginning so all channels are fully accessible
    if (tab == 'live' && allStreams.isNotEmpty) {
      list.insert(0, DashboardCategory(
        categoryId: 'all_live',
        categoryName: 'All Channels',
        items: allStreams,
      ));
    }

    // Fallback if list is empty
    if (list.isEmpty && allStreams.isNotEmpty) {
      list.add(DashboardCategory(
        categoryId: 'all',
        categoryName: 'All Items',
        items: allStreams,
      ));
    }

    _dashboardCategories = list;
  }

  Future<void> _loadFavoritesData(String code) async {
    final liveStreams = await IptvApiClient.getStreams(code, 'live', '');
    final vodStreams = await IptvApiClient.getStreams(code, 'movies', '');
    final seriesStreams = await IptvApiClient.getStreams(code, 'series', '');

    List<StreamItem> favLive = liveStreams.where((s) => _favoriteIds.contains(s.streamId)).toList();
    List<StreamItem> favMovies = vodStreams.where((s) => _favoriteIds.contains(s.streamId)).toList();
    List<StreamItem> favSeries = seriesStreams.where((s) => _favoriteIds.contains(s.streamId)).toList();

    List<DashboardCategory> list = [];
    if (favLive.isNotEmpty) {
      list.add(DashboardCategory(categoryId: 'fav_live', categoryName: 'Live TV', items: favLive));
    }
    if (favMovies.isNotEmpty) {
      list.add(DashboardCategory(categoryId: 'fav_movies', categoryName: 'Movies', items: favMovies));
    }
    if (favSeries.isNotEmpty) {
      list.add(DashboardCategory(categoryId: 'fav_series', categoryName: 'Series', items: favSeries));
    }

    _dashboardCategories = list;
  }

  Future<void> fetchStreamsForCategory(String code, String type, String categoryId) async {
    _isLoading = true;
    _categoryStreams = [];
    notifyListeners();

    _categoryStreams = await IptvApiClient.getStreams(code, type, categoryId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String streamId, String code) async {
    await StorageService.toggleFavorite(streamId);
    await loadFavorites();
    if (_currentTab == 'favorites') {
      await loadData(code);
    }
    notifyListeners();
  }
}
