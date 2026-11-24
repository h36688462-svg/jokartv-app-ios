import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/iptv_models.dart';
import '../providers/auth_provider.dart';
import '../providers/iptv_provider.dart';
import '../services/iptv_api_client.dart';
import '../services/tmdb_service.dart';
import 'player_screen.dart';

class VodDetailScreen extends StatefulWidget {
  final String vodId;
  final String vodName;
  final String? vodIcon;
  final String? containerExtension;
  final String? initialPlot;
  final String? initialGenre;
  final String? initialCast;
  final String? initialReleaseDate;
  final String? initialRating;
  final String? initialDirector;
  final String? initialDuration;

  const VodDetailScreen({
    super.key,
    required this.vodId,
    required this.vodName,
    this.vodIcon,
    this.containerExtension,
    this.initialPlot,
    this.initialGenre,
    this.initialCast,
    this.initialReleaseDate,
    this.initialRating,
    this.initialDirector,
    this.initialDuration,
  });

  @override
  State<VodDetailScreen> createState() => _VodDetailScreenState();
}

class _VodDetailScreenState extends State<VodDetailScreen> {
  VodDetails? _vodDetails;
  Map<String, dynamic>? _tmdbData;
  bool _isLoadingTmdb = true;
  int _selectedTab = 0; // 0: Recommended, 1: Special Contents (Trailer)

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    IptvApiClient.getVodInfo(auth.activeCode, widget.vodId).then((details) {
      if (mounted && details != null) {
        setState(() => _vodDetails = details);
      }
    });

    // Instant load from cache if available, or fetch in background
    final tmdb = await TmdbService.fetchMetadata(widget.vodName, 'movies');
    if (mounted) {
      setState(() {
        _tmdbData = tmdb;
        _isLoadingTmdb = false;
      });
    }
  }

  void _playMovie() {
    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => PlayerScreen(
          streamId: widget.vodId,
          streamType: 'movies',
          streamName: widget.vodName,
          containerExtension: widget.containerExtension ?? _vodDetails?.containerExtension,
        ),
      ),
    );
  }

  Future<void> _launchTrailer(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch trailer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iptv = Provider.of<IptvProvider>(context);
    List<StreamItem> recommendedMovies = [];
    for (var cat in iptv.dashboardCategories) {
      if (cat.items.any((item) => item.streamId == widget.vodId)) {
        recommendedMovies = cat.items.where((item) => item.streamId != widget.vodId).toList();
        break;
      }
    }
    if (recommendedMovies.isEmpty) {
      for (var cat in iptv.dashboardCategories) {
        recommendedMovies.addAll(cat.items.where((item) => item.streamId != widget.vodId));
      }
    }
    if (recommendedMovies.length > 10) {
      recommendedMovies = recommendedMovies.take(10).toList();
    }

    final backdropPath = _tmdbData?['backdrop_path']?.toString();
    final backdropUrl = backdropPath != null ? TmdbService.getImageUrl(backdropPath, size: 'w1280') : (widget.vodIcon ?? '');
    final clearLogoUrl = TmdbService.getClearLogo(_tmdbData);
    
    final tmdbTitle = _tmdbData?['title']?.toString() ?? widget.vodName;
    final voteAverage = _tmdbData?['vote_average']?.toString() ?? widget.initialRating ?? '7.5';
    final voteCount = _tmdbData?['vote_count']?.toString() ?? '1.6k';
    final ratingPercent = (double.tryParse(voteAverage) ?? 7.5) * 10;

    final releaseDate = _tmdbData?['release_date']?.toString() ?? widget.initialReleaseDate ?? '2025';
    final runtimeMinutes = _tmdbData?['runtime']?.toString() ?? '130';

    final credits = _tmdbData?['credits'] as Map<String, dynamic>?;
    final castList = credits?['cast'] as List? ?? [];

    final genresList = _tmdbData?['genres'] as List?;
    final genresText = genresList != null && genresList.isNotEmpty
        ? genresList.map((g) => g['name']).join('، ')
        : (_vodDetails?.genre ?? widget.initialGenre ?? 'رعب، فانتازيا، رومانسية');

    final overviewText = _tmdbData?['overview']?.toString() ?? widget.initialPlot ?? '';

    final providers = _tmdbData?['watch/providers']?['results']?['AR']?['flatrate'] as List? ??
        _tmdbData?['watch/providers']?['results']?['US']?['flatrate'] as List?;

    final trailerUrl = TmdbService.getYouTubeTrailerUrl(_tmdbData);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 30,
                spreadRadius: 10,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Wide Header Backdrop (16:9) with Play Button in center
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: Container(
                          color: const Color(0xFF0F172A),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (backdropUrl.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: backdropUrl,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF1F1F1F)),
                                )
                              else
                                Container(color: const Color(0xFF1F1F1F)),

                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black.withOpacity(0.4), const Color(0xFF141414)],
                                  ),
                                ),
                              ),

                              Center(
                                child: InkWell(
                                  onTap: _playMovie,
                                  borderRadius: BorderRadius.circular(40),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Movie Details Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (clearLogoUrl != null && clearLogoUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: clearLogoUrl,
                                height: 75,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => Text(
                                  tmdbTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              Text(
                                tmdbTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 12),

                            // Metadata Row: [12] (1.6k reviews) 73% ★
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white54),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('12', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Text('($voteCount reviews) ${ratingPercent.toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(width: 6),
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                              ],
                            ),
                            const SizedBox(height: 6),

                            Text(
                              '$releaseDate | $runtimeMinutes\'',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 14),

                            // Cast Photos Horizontal Row (صور الممثلين)
                            if (castList.isNotEmpty) ...[
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Cast', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 95,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: castList.length,
                                  itemBuilder: (context, index) {
                                    final actor = castList[index];
                                    final profilePath = actor['profile_path']?.toString();
                                    final actorName = actor['name']?.toString() ?? '';
                                    final profileUrl = profilePath != null ? TmdbService.getImageUrl(profilePath, size: 'w185') : '';

                                    return Container(
                                      width: 65,
                                      margin: const EdgeInsets.only(right: 10),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Colors.white10,
                                            backgroundImage: profileUrl.isNotEmpty ? CachedNetworkImageProvider(profileUrl) : null,
                                            child: profileUrl.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            actorName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (genresText.isNotEmpty) ...[
                              Text(
                                'Genres: $genresText',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Plot / Storyline
                            if (overviewText.isNotEmpty) ...[
                              Text(
                                overviewText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Watch Providers ("Also on")
                            if (providers != null && providers.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ...providers.take(4).map((p) {
                                    final logo = TmdbService.getImageUrl(p['logo_path'], size: 'w92');
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(imageUrl: logo, height: 28, width: 28, fit: BoxFit.cover),
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  const Text('Also on', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Tabs Header: Recommended | Special contents (Trailer)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 0),
                                  child: Text(
                                    'Recommended',
                                    style: TextStyle(
                                      color: _selectedTab == 0 ? Colors.white : Colors.grey,
                                      fontSize: 16,
                                      fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 1),
                                  child: Text(
                                    'Special contents (Trailer)',
                                    style: TextStyle(
                                      color: _selectedTab == 1 ? Colors.white : Colors.grey,
                                      fontSize: 16,
                                      fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Tab Content
                            if (_selectedTab == 0) ...[
                              if (recommendedMovies.isNotEmpty)
                                SizedBox(
                                  height: 170,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: recommendedMovies.length,
                                    itemBuilder: (context, index) {
                                      final rec = recommendedMovies[index];
                                      return InkWell(
                                        onTap: () {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute<dynamic>(
                                              builder: (_) => VodDetailScreen(
                                                vodId: rec.streamId,
                                                vodName: rec.name,
                                                vodIcon: rec.streamIcon,
                                                containerExtension: rec.containerExtension,
                                                initialPlot: rec.plot,
                                                initialGenre: rec.genre,
                                                initialCast: rec.cast,
                                                initialReleaseDate: rec.releaseDate,
                                                initialRating: rec.rating,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 110,
                                          margin: const EdgeInsets.only(right: 10),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: rec.streamIcon != null && rec.streamIcon!.isNotEmpty
                                                ? CachedNetworkImage(imageUrl: rec.streamIcon!, fit: BoxFit.cover)
                                                : Container(color: Colors.white10),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ] else ...[
                              if (trailerUrl != null)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE50914),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _launchTrailer(trailerUrl),
                                  icon: const Icon(Icons.play_circle_fill, size: 24),
                                  label: const Text('Play Official Trailer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                )
                              else
                                const Text('No trailer available for this title.', style: TextStyle(color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Top-Left Close Button (X)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
