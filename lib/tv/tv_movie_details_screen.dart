import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/tmdb_service.dart';
import '../services/storage_service.dart';
import 'playback_database.dart';
import 'tv_player_screen.dart';
import 'tv_scaffold.dart';

class TVMovieDetailsScreen extends StatefulWidget {
  final String movieId;
  final String movieName;

  const TVMovieDetailsScreen({
    super.key,
    required this.movieId,
    required this.movieName,
  });

  @override
  State<TVMovieDetailsScreen> createState() => _TVMovieDetailsScreenState();
}

class _TVMovieDetailsScreenState extends State<TVMovieDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tmdbData;
  bool _isFavorite = false;
  int _savedProgressMs = 0;
  final FocusNode _playButtonFocusNode = FocusNode();
  final FocusNode _favoriteButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _checkFavorite();
    _loadProgress();
  }

  Future<void> _loadMetadata() async {
    final data = await TmdbService.fetchMetadata(widget.movieName, 'movie');
    if (mounted) {
      setState(() {
        _tmdbData = data;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_playButtonFocusNode);
      });
    }
  }

  Future<void> _checkFavorite() async {
    final fav = await StorageService.isFavorite(widget.movieId);
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  Future<void> _loadProgress() async {
    final ms = await PlaybackDatabase.getProgress(widget.movieId);
    if (mounted) {
      setState(() => _savedProgressMs = ms);
    }
  }

  Future<void> _toggleFavorite() async {
    await PlaybackDatabase.toggleFavorite(widget.movieId);
    await _checkFavorite();
  }

  @override
  void dispose() {
    _playButtonFocusNode.dispose();
    _favoriteButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backdropPath = _tmdbData?['backdrop_path']?.toString() ?? '';
    final posterPath = _tmdbData?['poster_path']?.toString() ?? '';
    final backdropUrl = TmdbService.getImageUrl(backdropPath, size: 'w1280');
    final posterUrl = TmdbService.getImageUrl(posterPath, size: 'w500');
    final overview = _tmdbData?['overview']?.toString() ?? 'استمتع بمشاهدة أحدث الأفلام الحصرية بجودة عالية وبدون تقطيع عبر منصة Jokar TV.';
    final releaseDate = _tmdbData?['release_date']?.toString() ?? '2026';
    final releaseYear = releaseDate.isNotEmpty && releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '2026';
    final voteAverage = _tmdbData?['vote_average']?.toString() ?? '8.5';
    final runtime = _tmdbData?['runtime']?.toString() ?? '120';
    final genres = (_tmdbData?['genres'] as List?)?.map((g) => g['name'].toString()).join(' • ') ?? 'دراما • تشويق';
    final clearLogo = TmdbService.getClearLogo(_tmdbData);

    return TVScaffold(
      title: widget.movieName,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : Stack(
              fit: StackFit.expand,
              children: [
                // Backdrop Banner Background
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
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                          const Color(0xFF0B0B0B),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 280,
                          height: 420,
                          child: posterUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: posterUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF1F1F1F)),
                                )
                              : const ColoredBox(color: Color(0xFF1F1F1F)),
                        ),
                      ),
                      const SizedBox(width: 48),

                      // Details & Actions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (clearLogo != null && clearLogo.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: clearLogo,
                                height: 70,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => Text(
                                  widget.movieName,
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              Text(
                                widget.movieName,
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 12),

                            // Meta row
                            Row(
                              children: [
                                Text(releaseYear, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white54),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('HD', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Text('$runtime min', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                                const SizedBox(width: 12),
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(voteAverage, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Genres
                            Text(genres, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 20),

                            // Overview
                            Text(
                              overview,
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 36),

                            // Action Buttons (Play & Favorite)
                            Row(
                              children: [
                                // Play / Resume Button
                                Focus(
                                  focusNode: _playButtonFocusNode,
                                  child: Builder(
                                    builder: (context) {
                                      final isFocused = Focus.of(context).hasFocus;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        transform: isFocused ? Matrix4.diagonal3Values(1.08, 1.08, 1.0) : Matrix4.identity(),
                                        transformAlignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isFocused ? const Color(0xFF3B82F6) : Colors.white,
                                          borderRadius: BorderRadius.circular(28),
                                          boxShadow: isFocused
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF3B82F6).withOpacity(0.7),
                                                    blurRadius: 16,
                                                    spreadRadius: 3,
                                                  )
                                                ]
                                              : [],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<dynamic>(
                                                  builder: (_) => TVPlayerScreen(
                                                    streamType: 'movies',
                                                    streamName: widget.movieName,
                                                    streamId: widget.movieId,
                                                  ),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(28),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.play_arrow,
                                                    color: isFocused ? Colors.white : Colors.black,
                                                    size: 32,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    _savedProgressMs > 0 ? 'Resume Playing' : 'Play',
                                                    style: TextStyle(
                                                      color: isFocused ? Colors.white : Colors.black,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Favorite Button
                                Focus(
                                  focusNode: _favoriteButtonFocusNode,
                                  child: Builder(
                                    builder: (context) {
                                      final isFocused = Focus.of(context).hasFocus;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        transform: isFocused ? Matrix4.diagonal3Values(1.08, 1.08, 1.0) : Matrix4.identity(),
                                        transformAlignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isFocused ? const Color(0xFF3B82F6) : const Color(0xFF1E1E1E),
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: isFocused ? Colors.white : Colors.white24,
                                            width: isFocused ? 2.5 : 1,
                                          ),
                                          boxShadow: isFocused
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF3B82F6).withOpacity(0.6),
                                                    blurRadius: 12,
                                                    spreadRadius: 2,
                                                  )
                                                ]
                                              : [],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _toggleFavorite,
                                            borderRadius: BorderRadius.circular(28),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                                                    color: _isFavorite ? const Color(0xFFE50914) : Colors.white,
                                                    size: 28,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    _isFavorite ? 'In Favorites' : 'Add to Favorites',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
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
}
