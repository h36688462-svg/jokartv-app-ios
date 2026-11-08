import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/iptv_models.dart';
import '../providers/auth_provider.dart';
import '../providers/iptv_provider.dart';
import 'player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  String _selectedCategoryId = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final iptv = Provider.of<IptvProvider>(context, listen: false);
      iptv.setTab('live', auth.activeCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final iptv = Provider.of<IptvProvider>(context);

    // Filter live streams based on selected category or search, excluding movies/vod/series
    List<StreamItem> liveChannels = [];
    for (var cat in iptv.dashboardCategories) {
      if (_selectedCategoryId.isEmpty || _selectedCategoryId == 'all_live' || cat.categoryId == _selectedCategoryId) {
        liveChannels.addAll(cat.items.where((item) => item.streamType != 'movies' && item.streamType != 'vod' && item.streamType != 'series'));
      }
    }
    if (liveChannels.isEmpty) {
      for (var cat in iptv.dashboardCategories) {
        liveChannels.addAll(cat.items.where((item) => item.streamType != 'movies' && item.streamType != 'vod' && item.streamType != 'series'));
      }
    }

    final filteredChannels = liveChannels.where((ch) {
      if (_searchQuery.isEmpty) return true;
      return ch.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      body: Row(
        children: [
          // Left Sidebar: Server Categories & Groups with Channel Counts
          Container(
            width: 260,
            color: const Color(0xFF0F172A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'CATEGORIES',
                    style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: iptv.dashboardCategories.length,
                    itemBuilder: (context, index) {
                      final cat = iptv.dashboardCategories[index];
                      final liveCount = cat.items.where((item) => item.streamType != 'movies' && item.streamType != 'vod' && item.streamType != 'series').length;
                      IconData icon = Icons.tv;
                      final nameLower = cat.categoryName.toLowerCase();
                      if (nameLower.contains('sport')) icon = Icons.sports_soccer;
                      else if (nameLower.contains('news')) icon = Icons.newspaper;
                      else if (nameLower.contains('movie') || nameLower.contains('cinema')) icon = Icons.movie;
                      else if (nameLower.contains('kids') || nameLower.contains('animation')) icon = Icons.child_care;
                      else if (nameLower.contains('islam') || nameLower.contains('quran')) icon = Icons.mosque;
                      else if (nameLower.contains('music')) icon = Icons.music_note;
                      else if (nameLower.contains('all')) icon = Icons.all_inclusive;

                      return _buildCategoryTile(cat.categoryId, cat.categoryName, icon, liveCount);
                    },
                  ),
                ),
              ],
            ),
          ),

          // IPTVX Right Main Area: Search Bar & Channel Grid with TV Focus & Quality Badges
          Expanded(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onTap: () {
                      SystemChannels.textInput.invokeMethod('TextInput.show');
                    },
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search channel name (e.g. BEIN Sports, MBC 1)...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                // Channels Grid View
                Expanded(
                  child: filteredChannels.isEmpty
                      ? const Center(
                          child: Text('No channels found in this category.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredChannels.length,
                          itemBuilder: (context, index) {
                            final channel = filteredChannels[index];
                            final upperName = channel.name.toUpperCase();
                            String quality = 'LIVE';
                            Color badgeColor = const Color(0xFF475569);
                            if (upperName.contains('4K')) {
                              quality = '4K';
                              badgeColor = const Color(0xFFE11D48);
                            } else if (upperName.contains('FHD')) {
                              quality = 'FHD';
                              badgeColor = const Color(0xFF7C3AED);
                            } else if (upperName.contains('HD')) {
                              quality = 'HD';
                              badgeColor = const Color(0xFF2563EB);
                            }

                            return Focus(
                              child: Builder(
                                builder: (context) {
                                  final isFocused = Focus.of(context).hasFocus;
                                  return InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<dynamic>(
                                          builder: (_) => PlayerScreen(
                                            streamId: channel.streamId,
                                            streamType: 'live',
                                            streamName: channel.name,
                                            containerExtension: channel.containerExtension,
                                            playlistChannels: filteredChannels,
                                            currentChannelIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isFocused ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isFocused ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                                          width: isFocused ? 3 : 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Center(
                                                    child: channel.streamIcon != null && channel.streamIcon!.isNotEmpty
                                                        ? CachedNetworkImage(
                                                            imageUrl: channel.streamIcon!,
                                                            fit: BoxFit.contain,
                                                            width: 64,
                                                            height: 64,
                                                            errorWidget: (context, url, error) => const Icon(Icons.tv, color: Colors.white54, size: 32),
                                                          )
                                                        : const Icon(Icons.tv, color: Colors.white54, size: 32),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  channel.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'No EPG data available',
                                                  style: TextStyle(color: Colors.grey, fontSize: 10),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Quality Badge Top-Right
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: badgeColor,
                                                borderRadius: const BorderRadius.only(
                                                  topRight: Radius.circular(10),
                                                  bottomLeft: Radius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                quality,
                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String id, String title, IconData icon, int count) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          final isSelected = _selectedCategoryId == id;
          if (isFocused) {
            Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 150));
          }
          return Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : (isFocused ? const Color(0xFF1E293B) : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 1.5),
              ),
              child: ListTile(
                leading: Icon(icon, color: isSelected || isFocused ? Colors.white : Colors.grey, size: 20),
                title: Text(
                  title,
                  style: TextStyle(
                    color: isSelected || isFocused ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected || isFocused ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white24 : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected || isFocused ? Colors.white : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedCategoryId = id;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
