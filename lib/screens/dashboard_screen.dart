import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/iptv_models.dart';
import '../providers/auth_provider.dart';
import '../providers/iptv_provider.dart';
import '../providers/parental_control_provider.dart';
import '../widgets/pin_dialog.dart';
import 'player_screen.dart';
import 'series_detail_screen.dart';
import 'vod_detail_screen.dart';
import 'settings_screen.dart';
import 'streams_screen.dart';
import 'tv_guide_screen.dart';
import 'user_profile_screen.dart';
import 'live_tv_screen.dart';
import '../widgets/iptvx_components.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final iptv = Provider.of<IptvProvider>(context, listen: false);
      iptv.loadData(auth.activeCode);
    });
  }

  void _onCategoryTapped(DashboardCategory cat) {
    final parental = Provider.of<ParentalControlProvider>(context, listen: false);

    if (parental.isCategoryLocked(cat.categoryName)) {
      showDialog<void>(
        context: context,
        builder: (_) => PinDialog(
          onConfirm: (pin) async {
            if (await parental.validatePin(pin)) {
              _navigateToCategoryStreams(cat);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN')),
                );
              }
            }
          },
        ),
      );
    } else {
      _navigateToCategoryStreams(cat);
    }
  }

  void _navigateToCategoryStreams(DashboardCategory cat) {
    final iptv = Provider.of<IptvProvider>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => StreamsScreen(
          categoryType: iptv.currentTab,
          categoryId: cat.categoryId,
          categoryName: cat.categoryName,
        ),
      ),
    );
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

  void _showGlobalSearchDialog() {
    final iptv = Provider.of<IptvProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<StreamItem> allItems = [];
            for (var cat in iptv.dashboardCategories) {
              allItems.addAll(cat.items.where((item) {
                if (iptv.currentTab == 'live') return item.streamType == 'live' || item.streamType.isEmpty;
                if (iptv.currentTab == 'movies') return item.streamType == 'movies' || item.streamType == 'vod';
                if (iptv.currentTab == 'series') return item.streamType == 'series';
                return true;
              }));
            }
            final searchResults = allItems.where((item) {
              if (query.isEmpty) return false;
              final q = query.toLowerCase();
              return item.name.toLowerCase().contains(q);
            }).toList();

            return Dialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          child: Focus(
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent) {
                                if (event.logicalKey == LogicalKeyboardKey.escape ||
                                    event.logicalKey == LogicalKeyboardKey.goBack ||
                                    event.logicalKey == LogicalKeyboardKey.arrowDown ||
                                    event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                  node.unfocus();
                                  return KeyEventResult.handled;
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            child: TextField(
                              autofocus: true,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: const InputDecoration(
                                hintText: 'Search channels, movies, series...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setDialogState(() => query = val);
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    // Results List
                    Expanded(
                      child: query.isEmpty
                          ? const Center(
                              child: Text('Use the TV remote to select letters and search...', style: TextStyle(color: Colors.grey, fontSize: 15)),
                            )
                          : searchResults.isEmpty
                              ? const Center(
                                  child: Text('No results found.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                                )
                              : ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final item = searchResults[index];
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
                                                        Text('Type: ${item.streamType.toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final iptv = Provider.of<IptvProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth > 600;

    return WillPopScope(
      onWillPop: () async {
        if (iptv.currentTab != 'movies') {
          iptv.setTab('movies', auth.activeCode);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0B),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: const Color(0xFF141414),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SafeArea(
            child: Row(
              children: [
                // Logo & Title Side by Side
                Row(
                  children: [
                    Image.asset(
                      'smartiptv_source/app/src/main/res/drawable/app_logo.png',
                      height: isTabletOrDesktop ? 40 : 32,
                      width: isTabletOrDesktop ? 40 : 32,
                      cacheWidth: 200,
                      cacheHeight: 200,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Jokar TV',
                      style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // Top Navigation Bar (Settings, TV Guide, TV Live, Shows, Movies)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildNavTabButton('movies', 'Movies', iptv, auth.activeCode),
                        _buildNavTabButton('series', 'Shows', iptv, auth.activeCode),
                        _buildNavTabButton('live', 'TV Live', iptv, auth.activeCode),
                        _buildGuideButton(context),
                        _buildNavTabButton('favorites', 'Favorites', iptv, auth.activeCode),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Global Search Icon Button
                _buildTvIconButton(
                  icon: Icons.search,
                  onPressed: _showGlobalSearchDialog,
                ),
                const SizedBox(width: 12),

                // Settings & Profile Icons
                _buildTvIconButton(
                  icon: Icons.settings,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildTvIconButton(
                  icon: Icons.account_circle,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(builder: (_) => const UserProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: iptv.currentTab == 'live'
          ? const LiveTvScreen()
          : iptv.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
              : iptv.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(iptv.error!, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                            onPressed: () => iptv.loadData(auth.activeCode),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    )
                  : iptv.dashboardCategories.isEmpty
                      ? const Center(
                          child: Text('No content available in this section.', style: TextStyle(color: Colors.grey)),
                        )
                      : Builder(
                          builder: (context) {
                            final isMediaTab = iptv.currentTab == 'movies' || iptv.currentTab == 'series';
                            List<StreamItem> allItems = [];
                            if (isMediaTab) {
                              for (var cat in iptv.dashboardCategories) {
                                allItems.addAll(cat.items);
                              }
                            }
                            final extraCount = isMediaTab ? 3 : 0;
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: iptv.dashboardCategories.length + extraCount,
                              itemBuilder: (context, index) {
                                if (isMediaTab) {
                                  if (index == 0) {
                                    return IptvxHeroBillboard(
                                      items: allItems,
                                      onPlay: (item) => _onStreamSelected(item),
                                      onInfo: (item) => _onStreamSelected(item),
                                      onFavorite: (item) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Added to favorites')),
                                        );
                                      },
                                    );
                                  } else if (index == 1) {
                                    return IptvxContinueWatchingRow(
                                      items: allItems,
                                      onPlay: (item) => _onStreamSelected(item),
                                    );
                                  } else if (index == 2) {
                                    return IptvxTop20Row(
                                      items: allItems,
                                      onTap: (item) => _onStreamSelected(item),
                                    );
                                  } else {
                                    final cat = iptv.dashboardCategories[index - 3];
                                    return _buildCategoryRow(cat, isTabletOrDesktop);
                                  }
                                } else {
                                  final cat = iptv.dashboardCategories[index];
                                  return _buildCategoryRow(cat, isTabletOrDesktop);
                                }
                              },
                            );
                          },
                        ),
      ),
    );
  }

  Widget _buildNavTabButton(String tabKey, String label, IptvProvider iptv, String activeCode) {
    final isSelected = iptv.currentTab == tabKey;
    final onTap = () => iptv.setTab(tabKey, activeCode);
    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (Intent intent) {
            onTap();
            return null;
          },
        ),
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE50914) : (isFocused ? const Color(0xFF3B82F6) : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: isFocused ? Colors.white : Colors.white24, width: isFocused ? 2 : 1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected || isFocused ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuideButton(BuildContext context) {
    final onTap = () {
      Navigator.of(context).push(
        MaterialPageRoute<dynamic>(builder: (_) => const TvGuideScreen()),
      );
    };
    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (Intent intent) {
            onTap();
            return null;
          },
        ),
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isFocused ? Colors.white : Colors.white24, width: isFocused ? 2 : 1),
              ),
              child: const Text(
                'TV Guide',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTvIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 1.5),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          );
        },
      ),
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
                  fontSize: label.length > 1 ? 12 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryRow(DashboardCategory cat, bool isTabletOrDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cat.categoryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FocusableActionDetector(
                actions: <Type, Action<Intent>>{
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (Intent intent) {
                      _onCategoryTapped(cat);
                      return null;
                    },
                  ),
                },
                child: Builder(
                  builder: (context) {
                    final isFocused = Focus.of(context).hasFocus;
                    return InkWell(
                      onTap: () => _onCategoryTapped(cat),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 1),
                        ),
                        child: const Row(
                          children: [
                            Text('See All', style: TextStyle(color: Color(0xFFE50914), fontSize: 13, fontWeight: FontWeight.bold)),
                            Icon(Icons.chevron_right, color: Color(0xFFE50914), size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Horizontal Posters List
        SizedBox(
          height: isTabletOrDesktop ? 210 : 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            cacheExtent: 1000,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cat.items.length,
            itemBuilder: (context, index) {
              final item = cat.items[index];
              return _buildPosterCard(item, isTabletOrDesktop);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPosterCard(StreamItem item, bool isTabletOrDesktop) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          if (isFocused) {
            Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 50));
          }
          return InkWell(
            onTap: () => _onStreamSelected(item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: isTabletOrDesktop ? 140 : 115,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                  width: isFocused ? 3 : 0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ColoredBox(
                        color: const Color(0xFF1F1F1F),
                        child: item.streamIcon != null && item.streamIcon!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.streamIcon!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                memCacheWidth: 200,
                                memCacheHeight: 300,
                                errorWidget: (context, url, error) => _buildPlaceholder(item.name),
                                placeholder: (context, url) => const ColoredBox(
                                  color: Colors.white10,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : _buildPlaceholder(item.name),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isFocused ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return ColoredBox(
      color: const Color(0xFF2B2B2B),
      child: Padding(
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
      ),
    );
  }
}
