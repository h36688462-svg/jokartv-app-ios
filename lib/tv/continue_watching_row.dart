import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/iptv_models.dart';
import '../services/storage_service.dart';
import 'tv_player_screen.dart';
import 'tv_series_details_screen.dart';

class TVContinueWatchingRow extends StatefulWidget {
  final String sectionType; // 'live', 'movies', 'series'

  const TVContinueWatchingRow({
    super.key,
    required this.sectionType,
  });

  @override
  State<TVContinueWatchingRow> createState() => _TVContinueWatchingRowState();
}

class _TVContinueWatchingRowState extends State<TVContinueWatchingRow> {
  List<StreamItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService.getHistory();
    final filtered = history.where((item) {
      if (widget.sectionType == 'series') {
        return item.streamType == 'series';
      } else if (widget.sectionType == 'movies') {
        return item.streamType == 'movies' || item.streamType == 'vod' || item.streamType.isEmpty;
      } else {
        return item.streamType == 'live';
      }
    }).toList();

    if (mounted) {
      setState(() {
        _historyItems = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_historyItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
          child: Row(
            children: const [
              Icon(Icons.history, color: Color(0xFF3B82F6), size: 22),
              SizedBox(width: 10),
              Text(
                'Continue Watching (متابعة المشاهدة)',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 36),
            itemCount: _historyItems.length,
            itemBuilder: (context, index) {
              final item = _historyItems[index];
              return Focus(
                child: Builder(
                  builder: (context) {
                    final isFocused = Focus.of(context).hasFocus;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      transform: isFocused ? Matrix4.diagonal3Values(1.08, 1.08, 1.0) : Matrix4.identity(),
                      transformAlignment: Alignment.center,
                      width: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFocused ? const Color(0xFF3B82F6) : Colors.white12,
                          width: isFocused ? 3.5 : 1,
                        ),
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.7),
                                  blurRadius: 16,
                                  spreadRadius: 3,
                                )
                              ]
                            : [
                                const BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ],
                      ),
                      child: Material(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            if (widget.sectionType == 'series') {
                              Navigator.of(context).push(
                                MaterialPageRoute<dynamic>(
                                  builder: (_) => TVSeriesDetailsScreen(
                                    seriesId: item.streamId,
                                    seriesName: item.name,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute<dynamic>(
                                  builder: (_) => TVPlayerScreen(
                                    streamType: widget.sectionType,
                                    streamName: item.name,
                                    streamId: item.streamId,
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: item.streamIcon != null && item.streamIcon!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: item.streamIcon!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => _buildPlaceholder(item.name),
                                          placeholder: (_, __) => const ColoredBox(color: Colors.white10),
                                        )
                                      : _buildPlaceholder(item.name),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isFocused ? Colors.white : Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: const LinearProgressIndicator(
                                        value: 0.65,
                                        backgroundColor: Colors.white24,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }
}
