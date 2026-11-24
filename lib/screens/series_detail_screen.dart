import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/iptv_models.dart';
import '../providers/auth_provider.dart';
import '../services/iptv_api_client.dart';
import '../services/tmdb_service.dart';
import 'player_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final String seriesId;
  final String seriesName;

  const SeriesDetailScreen({
    super.key,
    required this.seriesId,
    required this.seriesName,
  });

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  bool _isLoading = true;
  SeriesDetails? _seriesDetails;
  Map<String, dynamic>? _tmdbData;
  String? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Fetch IPTV series info
    IptvApiClient.getSeriesInfo(auth.activeCode, widget.seriesId).then((details) {
      if (mounted && details != null) {
        setState(() {
          _seriesDetails = details;
          if (details.seasonList.isNotEmpty && _selectedSeason == null) {
            _selectedSeason = details.seasonList.first;
          }
        });
      }
    });

    // Fetch TMDB metadata for series
    final tmdb = await TmdbService.fetchMetadata(widget.seriesName, 'series');
    if (mounted) {
      setState(() {
        _tmdbData = tmdb;
        _isLoading = false;
      });
    }
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
    final backdropPath = _tmdbData?['backdrop_path']?.toString();
    final backdropUrl = backdropPath != null
        ? TmdbService.getImageUrl(backdropPath, size: 'w1280')
        : (_seriesDetails?.cover.isNotEmpty == true ? _seriesDetails!.cover : '');
    final clearLogoUrl = TmdbService.getClearLogo(_tmdbData);

    final tmdbTitle = _tmdbData?['name']?.toString() ?? widget.seriesName;
    final voteAverage = _tmdbData?['vote_average']?.toString() ?? _seriesDetails?.rating ?? '8.0';
    final voteCount = _tmdbData?['vote_count']?.toString() ?? '1.2k';
    final ratingPercent = (double.tryParse(voteAverage) ?? 8.0) * 10;

    final firstAirDate = _tmdbData?['first_air_date']?.toString() ?? _seriesDetails?.releaseDate ?? '2025';
    final credits = _tmdbData?['credits'] as Map<String, dynamic>?;
    final castList = credits?['cast'] as List? ?? [];

    final genresList = _tmdbData?['genres'] as List?;
    final genresText = genresList != null && genresList.isNotEmpty
        ? genresList.map((g) => g['name']).join('، ')
        : (_seriesDetails?.genre ?? 'دراما، تشويق، مغامرة');

    final overviewText = _tmdbData?['overview']?.toString() ?? _seriesDetails?.plot ?? '';
    final trailerUrl = TmdbService.getYouTubeTrailerUrl(_tmdbData);
    final providers = _tmdbData?['watch/providers']?['results']?['AR']?['flatrate'] as List? ??
        _tmdbData?['watch/providers']?['results']?['US']?['flatrate'] as List?;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(tmdbTitle, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _seriesDetails == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Backdrop Header & Play/Trailer overlay
                  SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (backdropUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: backdropUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: const Color(0xFF1F1F1F)),
                          )
                        else
                          Container(color: const Color(0xFF1F1F1F)),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.4), const Color(0xFF0B0B0B)],
                            ),
                          ),
                        ),
                        Center(
                          child: InkWell(
                            onTap: () {
                              if (_seriesDetails != null && _selectedSeason != null && _seriesDetails!.seasonsMap.containsKey(_selectedSeason)) {
                                final firstEp = _seriesDetails!.seasonsMap[_selectedSeason]!.first;
                                Navigator.of(context).push(
                                  MaterialPageRoute<dynamic>(
                                    builder: (_) => PlayerScreen(
                                      streamId: firstEp.id,
                                      streamType: 'series',
                                      streamName: '${widget.seriesName} - S${_selectedSeason}E${firstEp.episodeNum}',
                                      containerExtension: firstEp.containerExtension,
                                    ),
                                  ),
                                );
                              }
                            },
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

                  // 2. Series Details Section
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

                        // Metadata Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white54),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('TV', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Text('($voteCount reviews) ${ratingPercent.toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 6),
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),

                        Text(
                          '$firstAirDate | ${_seriesDetails?.seasonList.length ?? 1} Seasons',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 14),

                        // Trailer Button if available
                        if (trailerUrl != null) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () => _launchTrailer(trailerUrl),
                            icon: const Icon(Icons.movie, color: Color(0xFFE50914)),
                            label: const Text('Watch Trailer', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Cast Photos Horizontal Row
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

                        // Overview
                        if (overviewText.isNotEmpty) ...[
                          Text(
                            overviewText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Watch Providers
                        if (providers != null && providers.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...providers.take(4).map((p) {
                                final logoPath = p['logo_path']?.toString();
                                final logoUrl = logoPath != null ? TmdbService.getImageUrl(logoPath, size: 'w92') : '';
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: logoUrl.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(logoUrl), fit: BoxFit.cover) : null,
                                    color: Colors.white10,
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        const Divider(color: Colors.white24, height: 32),

                        // Season Selector
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Seasons & Episodes',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_seriesDetails != null && _seriesDetails!.seasonList.isNotEmpty)
                          SizedBox(
                            height: 45,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _seriesDetails!.seasonList.length,
                              itemBuilder: (context, index) {
                                final season = _seriesDetails!.seasonList[index];
                                final isSelected = _selectedSeason == season;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedSeason = season;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFE50914) : const Color(0xFF1F1F1F),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Text(
                                      'Season $season',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Episode List
                        if (_seriesDetails != null && _selectedSeason != null && _seriesDetails!.seasonsMap.containsKey(_selectedSeason))
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _seriesDetails!.seasonsMap[_selectedSeason]!.length,
                            itemBuilder: (context, index) {
                              final ep = _seriesDetails!.seasonsMap[_selectedSeason]![index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141414),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F1F1F),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.play_circle_fill, color: Color(0xFFE50914), size: 36),
                                  ),
                                  title: Text(
                                    'EP ${ep.episodeNum}: ${ep.title}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: const Text(
                                    'Full HD • 45m',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<dynamic>(
                                        builder: (_) => PlayerScreen(
                                          streamId: ep.id,
                                          streamType: 'series',
                                          streamName: '${widget.seriesName} - S${_selectedSeason}E${ep.episodeNum}',
                                          containerExtension: ep.containerExtension,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
