import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/iptv_models.dart';
import '../providers/auth_provider.dart';
import '../services/iptv_api_client.dart';
import '../services/tmdb_service.dart';
import 'playback_database.dart';
import 'tv_player_screen.dart';
import 'tv_scaffold.dart';

class TVSeriesDetailsScreen extends StatefulWidget {
  final String seriesId;
  final String seriesName;

  const TVSeriesDetailsScreen({
    super.key,
    required this.seriesId,
    required this.seriesName,
  });

  @override
  State<TVSeriesDetailsScreen> createState() => _TVSeriesDetailsScreenState();
}

class _TVSeriesDetailsScreenState extends State<TVSeriesDetailsScreen> {
  bool _isLoading = true;
  SeriesDetails? _seriesDetails;
  Map<String, dynamic>? _tmdbData;
  int _selectedSeasonIndex = 0;
  List<String> _watchedEpisodeIds = [];
  final FocusNode _firstSeasonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Fetch Series Info & TMDB Metadata in parallel
    final results = await Future.wait([
      IptvApiClient.getSeriesInfo(auth.activeCode, widget.seriesId),
      TmdbService.fetchMetadata(widget.seriesName, 'series'),
    ]);

    if (mounted) {
      setState(() {
        _seriesDetails = results[0] as SeriesDetails?;
        _tmdbData = results[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_firstSeasonFocusNode);
      });
    }

    final watched = await PlaybackDatabase.getWatchedEpisodes(widget.seriesId);
    if (mounted) {
      setState(() {
        _watchedEpisodeIds = watched;
      });
    }
  }

  Future<void> _toggleWatched(String episodeId) async {
    await PlaybackDatabase.toggleWatchedEpisode(widget.seriesId, episodeId);
    final watched = await PlaybackDatabase.getWatchedEpisodes(widget.seriesId);
    if (mounted) {
      setState(() {
        _watchedEpisodeIds = watched;
      });
    }
  }

  @override
  void dispose() {
    _firstSeasonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seasons = _seriesDetails?.seasonList ?? [];
    final episodesMap = _seriesDetails?.seasonsMap ?? {};
    final currentSeasonKey = seasons.isNotEmpty ? seasons[_selectedSeasonIndex] : '1';
    final currentEpisodes = episodesMap[currentSeasonKey] ?? [];

    final backdropPath = _tmdbData?['backdrop_path']?.toString() ?? '';
    final posterPath = _tmdbData?['poster_path']?.toString() ?? '';
    final backdropUrl = TmdbService.getImageUrl(backdropPath, size: 'w1280');
    final posterUrl = TmdbService.getImageUrl(posterPath, size: 'w500');
    final tmdbOverview = _tmdbData?['overview']?.toString();
    final plot = (tmdbOverview != null && tmdbOverview.isNotEmpty)
        ? tmdbOverview
        : (_seriesDetails?.plot ?? 'استمتع بمشاهدة أحدث المسلسلات والحلقات الحصرية بجودة عالية وبدون تقطيع عبر منصة Jokar TV.');

    final firstAirDate = _tmdbData?['first_air_date']?.toString() ?? '2026';
    final releaseYear = firstAirDate.isNotEmpty && firstAirDate.length >= 4 ? firstAirDate.substring(0, 4) : '2026';
    final voteAverage = _tmdbData?['vote_average']?.toString() ?? (_seriesDetails?.rating ?? '8.5');
    final genres = (_tmdbData?['genres'] as List?)?.map((g) => g['name'].toString()).join(' • ') ?? (_seriesDetails?.genre ?? 'دراما • تشويق');
    final seriesCover = posterUrl.isNotEmpty ? posterUrl : (_seriesDetails?.cover ?? '');

    return TVScaffold(
      title: widget.seriesName,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : Stack(
              fit: StackFit.expand,
              children: [
                // Hero Backdrop Background
                if (backdropUrl.isNotEmpty)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: backdropUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF141414)),
                    ),
                  ),

                // Dark Gradient Overlays
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.75),
                          Colors.black.withOpacity(0.6),
                          const Color(0xFF0B0B0B),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content Layout
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Series Poster & Summary
                      SizedBox(
                        width: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 340,
                                width: double.infinity,
                                child: seriesCover.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: seriesCover,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF1F1F1F)),
                                      )
                                    : const ColoredBox(color: Color(0xFF1F1F1F)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.seriesName,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(releaseYear, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(voteAverage, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(genres, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(
                                plot,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),

                      // Right: Seasons & Episodes List
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seasons Tabs
                            if (seasons.isNotEmpty) ...[
                              const Text('Seasons (الأجزاء)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 50,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: seasons.length,
                                  itemBuilder: (context, index) {
                                    final seasonNum = seasons[index];
                                    final isSelected = _selectedSeasonIndex == index;
                                    return _buildSeasonTab(
                                      'Season $seasonNum',
                                      index,
                                      isSelected,
                                      focusNode: index == 0 ? _firstSeasonFocusNode : null,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Episodes List Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Episodes (الحلقات)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Total: ${currentEpisodes.length} Episodes', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Episodes ListView
                            Expanded(
                              child: currentEpisodes.isEmpty
                                  ? const Center(child: Text('No episodes available in this season.', style: TextStyle(color: Colors.grey)))
                                  : ListView.builder(
                                      itemCount: currentEpisodes.length,
                                      itemBuilder: (context, index) {
                                        final ep = currentEpisodes[index];
                                        final isWatched = _watchedEpisodeIds.contains(ep.id);
                                        return _buildEpisodeTile(ep, isWatched);
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSeasonTab(String title, int index, bool isSelected, {FocusNode? focusNode}) {
    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: isFocused ? Matrix4.diagonal3Values(1.08, 1.08, 1.0) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : (isFocused ? const Color(0xFF1E293B) : const Color(0xFF141414)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedSeasonIndex = index),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected || isFocused ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodeTile(EpisodeItem ep, bool isWatched) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: isFocused ? Matrix4.diagonal3Values(1.03, 1.03, 1.0) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isFocused ? const Color(0xFF1E293B) : const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isFocused ? const Color(0xFF3B82F6) : Colors.white10, width: isFocused ? 2.5 : 1),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await _toggleWatched(ep.id);
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (_) => TVPlayerScreen(
                          streamType: 'series',
                          streamName: '${ep.episodeNum}. ${ep.title}',
                          streamId: ep.id,
                          containerExtension: ep.containerExtension,
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Episode Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 48,
                          child: ep.cover.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: ep.cover,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF1F1F1F)),
                                  placeholder: (_, __) => const ColoredBox(color: Colors.white10),
                                )
                              : const ColoredBox(color: Color(0xFF1F1F1F)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ep.episodeNum,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ep.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Episode ${ep.episodeNum}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (isWatched)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text('Watched / تم المشاهدة', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 16),
                      const Icon(Icons.play_circle_fill, color: Color(0xFFE50914), size: 38),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
