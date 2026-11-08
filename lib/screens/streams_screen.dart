import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/iptv_models.dart';
import '../providers/auth_provider.dart';
import '../providers/iptv_provider.dart';
import 'player_screen.dart';
import 'series_detail_screen.dart';
import 'vod_detail_screen.dart';

class StreamsScreen extends StatefulWidget {
  final String categoryType;
  final String categoryId;
  final String categoryName;

  const StreamsScreen({
    super.key,
    required this.categoryType,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends State<StreamsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final iptv = Provider.of<IptvProvider>(context, listen: false);
      iptv.fetchStreamsForCategory(auth.activeCode, widget.categoryType, widget.categoryId);
    });
  }

  void _onStreamSelected(StreamItem stream) {
    if (stream.streamType == 'series') {
      Navigator.of(context).push(
        MaterialPageRoute<dynamic>(
          builder: (_) => SeriesDetailScreen(
            seriesId: stream.streamId,
            seriesName: stream.name,
          ),
        ),
      );
    } else if (stream.streamType == 'movies' || stream.streamType == 'vod') {
      Navigator.of(context).push(
        MaterialPageRoute<dynamic>(
          builder: (_) => VodDetailScreen(
            vodId: stream.streamId,
            vodName: stream.name,
            vodIcon: stream.streamIcon,
            containerExtension: stream.containerExtension,
            initialPlot: stream.plot,
            initialGenre: stream.genre,
            initialCast: stream.cast,
            initialReleaseDate: stream.releaseDate,
            initialRating: stream.rating,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<dynamic>(
          builder: (_) => PlayerScreen(
            streamId: stream.streamId,
            streamType: stream.streamType,
            streamName: stream.name,
            containerExtension: stream.containerExtension,
          ),
        ),
      );
    }
  }

  void _showSearchDialog() {
    bool isArabic = false;
    String query = _searchQuery;

    List<String> getCurrentKeys(bool arabic) {
      if (arabic) {
        return [
          'أ','ب','ت','ث','ج','ح','خ','د','ذ','ر',
          'ز','س','ش','ص','ض','ط','ظ','ع','غ','ف',
          'ق','ك','ل','م','ن','هـ','و','ي','ة',
          '0','1','2','3','4','5','6','7','8','9',
          'EN','⌫','CLR'
        ];
      } else {
        return [
          'A','B','C','D','E','F','G','H','I','J',
          'K','L','M','N','O','P','Q','R','S','T',
          'U','V','W','X','Y','Z','0','1','2','3',
          '4','5','6','7','8','9','AR','⌫','CLR'
        ];
      }
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final iptv = Provider.of<IptvProvider>(context, listen: false);
            final filtered = iptv.categoryStreams.where((s) {
              if (query.isEmpty) return true;
              return s.name.toLowerCase().contains(query.toLowerCase());
            }).toList();

            final keys = getCurrentKeys(isArabic);

            return Dialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: FocusTraversalGroup(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.85,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF3B82F6), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 50,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1F1F),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                              ),
                              child: Text(
                                query.isEmpty ? 'Search in ${widget.categoryName}...' : query,
                                style: TextStyle(
                                  color: query.isEmpty ? Colors.grey : Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FocusableActionDetector(
                            actions: <Type, Action<Intent>>{
                              ActivateIntent: CallbackAction<ActivateIntent>(
                                onInvoke: (Intent intent) {
                                  Navigator.pop(context);
                                  return null;
                                },
                              ),
                            },
                            child: Builder(
                              builder: (context) {
                                final isFocused = Focus.of(context).hasFocus;
                                return InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 1.5),
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 10,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: keys.length,
                          itemBuilder: (context, index) {
                            final char = keys[index];
                            return _buildSearchKey(char, () {
                              setDialogState(() {
                                if (char == 'AR') {
                                  isArabic = true;
                                } else if (char == 'EN') {
                                  isArabic = false;
                                } else if (char == '⌫') {
                                  if (query.isNotEmpty) query = query.substring(0, query.length - 1);
                                } else if (char == 'CLR') {
                                  query = '';
                                } else {
                                  query += char;
                                }
                              });
                              setState(() {
                                _searchQuery = query;
                                _searchController.text = query;
                              });
                            });
                          },
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('No results found.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return FocusableActionDetector(
                                    actions: <Type, Action<Intent>>{
                                      ActivateIntent: CallbackAction<ActivateIntent>(
                                        onInvoke: (Intent intent) {
                                          Navigator.pop(context);
                                          _onStreamSelected(item);
                                          return null;
                                        },
                                      ),
                                    },
                                    child: Builder(
                                      builder: (context) {
                                        final isFocused = Focus.of(context).hasFocus;
                                        return InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                            _onStreamSelected(item);
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            margin: const EdgeInsets.symmetric(vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 1.5),
                                            ),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: SizedBox(
                                                    width: 45,
                                                    height: 45,
                                                    child: item.streamIcon != null && item.streamIcon!.isNotEmpty
                                                        ? CachedNetworkImage(
                                                            imageUrl: item.streamIcon!,
                                                            fit: BoxFit.cover,
                                                            errorWidget: (context, url, error) => const Icon(Icons.tv, color: Colors.white54),
                                                          )
                                                        : const Icon(Icons.tv, color: Colors.white54),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                      Text('Type: ${item.streamType.toUpperCase()}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 14),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchKey(String label, VoidCallback onPressed) {
    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (Intent intent) {
            onPressed();
            return null;
          },
        ),
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFF3B82F6) : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isFocused ? Colors.white : Colors.white12,
                  width: isFocused ? 2 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: label.length > 1 ? 12 : 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final iptv = Provider.of<IptvProvider>(context);

    final filteredStreams = iptv.categoryStreams.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.categoryName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar (Clickable TV Search Card)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FocusableActionDetector(
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (Intent intent) {
                    _showSearchDialog();
                    return null;
                  },
                ),
              },
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return InkWell(
                    onTap: _showSearchDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isFocused ? const Color(0xFF3B82F6) : const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _searchQuery.isEmpty ? 'Search in ${widget.categoryName}...' : _searchQuery,
                              style: TextStyle(
                                color: _searchQuery.isEmpty ? Colors.grey : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Streams Grid
          Expanded(
            child: iptv.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                : filteredStreams.isEmpty
                    ? const Center(
                        child: Text('No streams found.', style: TextStyle(color: Colors.grey)),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredStreams.length,
                        itemBuilder: (context, index) {
                          final stream = filteredStreams[index];
                          final isFav = iptv.favoriteIds.contains(stream.streamId);

                          return GestureDetector(
                            onTap: () => _onStreamSelected(stream),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                          child: stream.streamIcon != null && stream.streamIcon!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: stream.streamIcon!,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (context, url, error) => _buildPlaceholder(stream.name),
                                                )
                                              : _buildPlaceholder(stream.name),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          stream.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Favorite Button
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        iptv.toggleFavorite(stream.streamId, auth.activeCode);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isFav ? Icons.favorite : Icons.favorite_border,
                                          color: isFav ? const Color(0xFFE50914) : Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Container(
      color: const Color(0xFF2B2B2B),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ),
    );
  }
}
