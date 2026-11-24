import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/iptv_models.dart';
import '../providers/auth_provider.dart';
import '../services/iptv_api_client.dart';
import '../services/storage_service.dart';
import '../widgets/tv_focusable.dart';
import 'playback_database.dart';
import 'tv_player_screen.dart';
import 'tv_scaffold.dart';
import 'tv_series_details_screen.dart';
import 'tv_movie_details_screen.dart';

class TVContentGridScreen extends StatefulWidget {
  final String streamType; // 'live', 'movies', 'series'
  final String sectionTitle;

  const TVContentGridScreen({
    super.key,
    required this.streamType,
    required this.sectionTitle,
  });

  @override
  State<TVContentGridScreen> createState() => _TVContentGridScreenState();
}

class _TVContentGridScreenState extends State<TVContentGridScreen> {
  bool _isLoadingCategories = true;
  bool _isLoadingStreams = false;
  List<CategoryItem> _categories = [];
  List<StreamItem> _allSectionStreams = [];
  List<StreamItem> _streams = [];
  Map<String, int> _categoryCounts = {};
  String _selectedCategoryId = 'all';
  String _activeCode = '';
  String _searchQuery = '';
  final ScrollController _gridScrollController = ScrollController();
  final ScrollController _sidebarScrollController = ScrollController();

  // Explicit Focus Nodes for Sidebar and Grid
  final FocusNode _sidebarFocusNode = FocusNode();
  final FocusNode _gridFocusNode = FocusNode();
  final List<FocusNode> _sidebarCategoryFocusNodes = [];
  final List<FocusNode> _streamCardFocusNodes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _activeCode = auth.activeCode;
      if (_activeCode.isEmpty) {
        final source = await StorageService.getMediaSource();
        _activeCode = source?['url'] ?? '';
      }
      await _loadCategoriesAndStreams();
      if (!mounted) return;
      Future.microtask(() {
        if (mounted) {
          FocusScope.of(context).requestFocus(_sidebarFocusNode);
        }
      });
    });
  }

  @override
  void dispose() {
    _gridScrollController.dispose();
    _sidebarScrollController.dispose();
    _sidebarFocusNode.dispose();
    _gridFocusNode.dispose();
    for (var node in _sidebarCategoryFocusNodes) {
      node.dispose();
    }
    for (var node in _streamCardFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategoriesAndStreams() async {
    setState(() => _isLoadingCategories = true);
    String action;
    switch (widget.streamType) {
      case 'live':
        action = 'get_live_categories';
        break;
      case 'movies':
        action = 'get_vod_categories';
        break;
      case 'series':
        action = 'get_series_categories';
        break;
      default:
        action = 'get_vod_categories';
    }

    final cats = await IptvApiClient.getCategories(_activeCode, action);
    final allStreams = await IptvApiClient.getStreams(_activeCode, widget.streamType, '');

    final counts = <String, int>{};
    for (var s in allStreams) {
      final catId = s.categoryId ?? '';
      counts[catId] = (counts[catId] ?? 0) + 1;
    }

    if (mounted) {
      setState(() {
        _categories = cats;
        _allSectionStreams = allStreams;
        _categoryCounts = counts;
        _isLoadingCategories = false;
        _selectedCategoryId = 'all';
        _streams = allStreams;
        _updateSidebarFocusNodes(cats.length + 2);
        _updateStreamFocusNodes(allStreams.length);
      });

      Future.microtask(() {
        if (_sidebarCategoryFocusNodes.isNotEmpty) {
          _sidebarCategoryFocusNodes[0].requestFocus();
        }
      });
    }
  }

  Future<void> _loadStreams(String categoryId) async {
    setState(() => _isLoadingStreams = true);
    List<StreamItem> streams;
    if (categoryId == 'all') {
      streams = _allSectionStreams;
    } else if (categoryId == 'favorites') {
      final favIds = await PlaybackDatabase.getFavorites();
      streams = _allSectionStreams.where((s) => favIds.contains(s.streamId)).toList();
    } else {
      streams = _allSectionStreams.where((s) => s.categoryId == categoryId).toList();
      if (streams.isEmpty) {
        streams = await IptvApiClient.getStreams(_activeCode, widget.streamType, categoryId);
      }
    }
    if (mounted) {
      setState(() {
        _streams = streams;
        _isLoadingStreams = false;
        _updateStreamFocusNodes(streams.length);
      });
      Future.microtask(() {
        if (_streamCardFocusNodes.isNotEmpty) {
          _streamCardFocusNodes[0].requestFocus();
        }
      });
    }
  }

  void _updateSidebarFocusNodes(int count) {
    for (var node in _sidebarCategoryFocusNodes) {
      node.dispose();
    }
    _sidebarCategoryFocusNodes.clear();
    for (int i = 0; i < count; i++) {
      _sidebarCategoryFocusNodes.add(FocusNode());
    }
  }

  void _updateStreamFocusNodes(int count) {
    for (var node in _streamCardFocusNodes) {
      node.dispose();
    }
    _streamCardFocusNodes.clear();
    for (int i = 0; i < count; i++) {
      _streamCardFocusNodes.add(FocusNode());
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: const Text('Search Content', style: TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Type to search...',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                final filteredCount = _streams.where((item) {
                  if (_searchQuery.isEmpty) return true;
                  return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
                }).length;
                _updateStreamFocusNodes(filteredCount);
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done', style: TextStyle(color: Color(0xFFE50914))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStreams = _streams.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return TVScaffold(
      title: widget.sectionTitle,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          children: [
            // Left Sidebar: Categories List with FocusTraversalGroup
            FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Container(
                width: 310,
                color: const Color(0xFF141414),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: Text(
                        'Categories & Navigation',
                        style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),

                    // Fixed Top Sidebar Items
                    _buildFixedSidebarItem(0, 'All ${widget.sectionTitle}', 'all', Icons.all_inclusive, _allSectionStreams.length),
                    _buildFixedSidebarItem(1, 'Favorites (المفضلة)', 'favorites', Icons.favorite, null, isFavorite: true),

                    const Divider(color: Colors.white12, height: 1),

                    // Scrollable Category List
                    Expanded(
                      child: _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                          : _categories.isEmpty
                              ? const Center(child: Text('No categories found', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  controller: _sidebarScrollController,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final cat = _categories[index];
                                    final isSelected = _selectedCategoryId == cat.categoryId;
                                    final count = _categoryCounts[cat.categoryId] ?? 0;
                                    return _buildCategoryTile(index + 2, cat.categoryId, '${cat.categoryName} ($count)', isSelected);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Content Grid & Search Button
            Expanded(
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCategoryId == 'all'
                                    ? 'All ${widget.sectionTitle}'
                                    : _selectedCategoryId == 'favorites'
                                        ? 'Favorites (المفضلة)'
                                        : _categories.firstWhere((c) => c.categoryId == _selectedCategoryId, orElse: () => CategoryItem(categoryId: '', categoryName: widget.sectionTitle)).categoryName,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Items: ${filteredStreams.length}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          TvFocusable(
                            onTap: () => _showSearchDialog(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.search, color: Colors.grey, size: 20),
                                  SizedBox(width: 8),
                                  Text('Search / بحث', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Grid View with unblocked focus traversal and ensureVisible
                      Expanded(
                        child: _isLoadingStreams
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                            : filteredStreams.isEmpty
                                ? const Center(child: Text('No content found matching your search.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                                : GridView.builder(
                                    controller: _gridScrollController,
                                    padding: const EdgeInsets.only(bottom: 24),
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 180,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: filteredStreams.length,
                                    itemBuilder: (context, index) {
                                      final item = filteredStreams[index];
                                      return _buildStreamCard(index, item);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedSidebarItem(int nodeIndex, String title, String id, IconData icon, int? count, {bool isFavorite = false}) {
    final isSelected = _selectedCategoryId == id;
    final focusNode = nodeIndex < _sidebarCategoryFocusNodes.length ? _sidebarCategoryFocusNodes[nodeIndex] : FocusNode();

    return Focus(
      focusNode: focusNode,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (_streamCardFocusNodes.isNotEmpty) {
            Future.microtask(() => _streamCardFocusNodes[0].requestFocus());
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TvFocusable(
        focusNode: focusNode,
        onTap: () {
          setState(() {
            _selectedCategoryId = id;
            _searchQuery = '';
          });
          _loadStreams(id);
        },
        borderRadius: BorderRadius.circular(10),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: isFavorite ? Colors.redAccent : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count != null)
                Text(
                  '($count)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(int nodeIndex, String catId, String title, bool isSelected) {
    final focusNode = nodeIndex < _sidebarCategoryFocusNodes.length ? _sidebarCategoryFocusNodes[nodeIndex] : FocusNode();

    return Focus(
      focusNode: focusNode,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (_streamCardFocusNodes.isNotEmpty) {
            Future.microtask(() => _streamCardFocusNodes[0].requestFocus());
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TvFocusable(
        focusNode: focusNode,
        onTap: () {
          setState(() {
            _selectedCategoryId = catId;
            _searchQuery = '';
          });
          _loadStreams(catId);
        },
        borderRadius: BorderRadius.circular(10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildStreamCard(int index, StreamItem item) {
    final focusNode = index < _streamCardFocusNodes.length ? _streamCardFocusNodes[index] : FocusNode();
    return Focus(
      focusNode: focusNode,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final logical = event.logicalKey;
          // Explicitly return ignored for directional arrows so system spatial navigation moves freely across all items
          if (logical == LogicalKeyboardKey.arrowUp ||
              logical == LogicalKeyboardKey.arrowDown ||
              logical == LogicalKeyboardKey.arrowLeft ||
              logical == LogicalKeyboardKey.arrowRight) {
            return KeyEventResult.ignored;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TvFocusable(
        focusNode: focusNode,
        onTap: () {
          if (widget.streamType == 'series') {
            Navigator.of(context).push(
              MaterialPageRoute<dynamic>(
                builder: (_) => TVSeriesDetailsScreen(
                  seriesId: item.streamId,
                  seriesName: item.name,
                ),
              ),
            );
          } else if (widget.streamType == 'movies') {
            Navigator.of(context).push(
              MaterialPageRoute<dynamic>(
                builder: (_) => TVMovieDetailsScreen(
                  movieId: item.streamId,
                  movieName: item.name,
                ),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute<dynamic>(
                builder: (_) => TVPlayerScreen(
                  streamType: widget.streamType,
                  streamName: item.name,
                  streamId: item.streamId,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.streamIcon != null && item.streamIcon!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.streamIcon!,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 300,
                        errorWidget: (_, __, ___) => _buildPlaceholder(item.name),
                        placeholder: (_, __) => const ColoredBox(color: Colors.white10),
                      )
                    : _buildPlaceholder(item.name),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      color: const Color(0xFF1F1F1F),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
    );
  }
}
