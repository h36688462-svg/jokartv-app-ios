import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/iptv_models.dart';
import '../services/tmdb_service.dart';
import '../services/storage_service.dart';

class IptvxContinueWatchingRow extends StatefulWidget {
  final List<StreamItem> items;
  final Function(StreamItem) onPlay;

  const IptvxContinueWatchingRow({
    super.key,
    required this.items,
    required this.onPlay,
  });

  @override
  State<IptvxContinueWatchingRow> createState() => _IptvxContinueWatchingRowState();
}

class _IptvxContinueWatchingRowState extends State<IptvxContinueWatchingRow> {
  final Map<String, double> _progressMap = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final map = <String, double>{};
    for (var item in widget.items) {
      final ms = await StorageService.getProgress(item.streamId);
      if (ms > 0) {
        const totalDuration = 7200000.0;
        double progress = (ms / totalDuration).clamp(0.05, 0.95);
        map[item.streamId] = progress;
      }
    }
    if (mounted) {
      setState(() {
        _progressMap.addAll(map);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchableItems = widget.items.where((item) => _progressMap.containsKey(item.streamId)).toList();
    if (watchableItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Continue watching',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: watchableItems.length,
            itemBuilder: (context, index) {
              final item = watchableItems[index];
              final progress = _progressMap[item.streamId] ?? 0.0;

              return FocusableActionDetector(
                child: Builder(
                  builder: (context) {
                    final isFocused = Focus.of(context).hasFocus;
                    return InkWell(
                      onTap: () => widget.onPlay(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 240,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                            width: isFocused ? 3 : 0,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item.streamIcon != null && item.streamIcon!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.streamIcon!,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 400,
                                      memCacheHeight: 250,
                                      errorWidget: (_, __, ___) => Container(color: const Color(0xFF1F1F1F)),
                                    )
                                  : Container(color: const Color(0xFF1F1F1F)),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              left: 12,
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                                  minHeight: 4,
                                ),
                              ),
                            ),
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
    );
  }
}

class IptvxHeroBillboard extends StatelessWidget {
  final List<StreamItem> items;
  final Function(StreamItem) onPlay;
  final Function(StreamItem) onInfo;
  final Function(StreamItem) onFavorite;

  const IptvxHeroBillboard({
    super.key,
    required this.items,
    required this.onPlay,
    required this.onInfo,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final featured = items.first;

    return FutureBuilder<Map<String, dynamic>?>(
      future: TmdbService.fetchMetadata(featured.name, featured.streamType),
      builder: (context, snapshot) {
        final tmdbData = snapshot.data;
        final backdrop = TmdbService.getImageUrl(tmdbData?['backdrop_path']?.toString() ?? '', size: 'w1280');
        final clearLogo = TmdbService.getClearLogo(tmdbData);
        final genresList = tmdbData?['genres'] as List?;
        final genreText = genresList != null && genresList.isNotEmpty
            ? genresList.map((g) => g['name']).take(2).join(' • ')
            : (featured.genre ?? 'دراما • تشويق');
        final runtime = tmdbData?['runtime']?.toString() ?? '110';

        return SizedBox(
          height: 400,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (backdrop.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: backdrop,
                  fit: BoxFit.cover,
                  memCacheWidth: 1280,
                  memCacheHeight: 720,
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF141414)),
                )
              else if (featured.streamIcon != null)
                CachedNetworkImage(
                  imageUrl: featured.streamIcon!,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  memCacheHeight: 600,
                )
              else
                Container(color: const Color(0xFF141414)),

              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.1),
                      const Color(0xFF0B0B0B),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),

              Positioned(
                left: 24,
                bottom: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (clearLogo != null && clearLogo.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: clearLogo,
                        height: 65,
                        fit: BoxFit.contain,
                        memCacheWidth: 500,
                        memCacheHeight: 200,
                        errorWidget: (_, __, ___) => Text(
                          featured.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Text(
                        featured.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 8),

                    Text(
                      "$genreText • '$runtime",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.white, size: 26),
                              onPressed: () => onInfo(featured),
                            ),
                            const Text('Info', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(width: 32),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: () => onPlay(featured),
                          icon: const Icon(Icons.play_arrow, size: 28, color: Colors.black),
                          label: const Text('Play', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 32),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.star_border, color: Colors.white, size: 26),
                              onPressed: () => onFavorite(featured),
                            ),
                            const Text('Favorites', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class IptvxTop20Row extends StatelessWidget {
  final List<StreamItem> items;
  final Function(StreamItem) onTap;

  const IptvxTop20Row({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final topItems = items.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Trending this week',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: topItems.length,
              itemBuilder: (context, index) {
                final item = topItems[index];
                return FocusableActionDetector(
                  child: Builder(
                    builder: (context) {
                      final isFocused = Focus.of(context).hasFocus;
                      return InkWell(
                        onTap: () => onTap(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 155,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                width: 105,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  transform: isFocused ? Matrix4.diagonal3Values(1.1, 1.1, 1.0) : Matrix4.identity(),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                                      width: isFocused ? 3 : 0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.streamIcon != null && item.streamIcon!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: item.streamIcon!,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 250,
                                            memCacheHeight: 350,
                                            errorWidget: (_, __, ___) => _buildPlaceholder(item.name),
                                            placeholder: (_, __) => _buildPlaceholder(item.name),
                                          )
                                        : _buildPlaceholder(item.name),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -2,
                                bottom: -10,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 135,
                                    fontWeight: FontWeight.w900,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 5
                                      ..color = Colors.white60,
                                  ),
                                ),
                              ),
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
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String title) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
