import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/iptv_models.dart';
import '../providers/auth_provider.dart';
import '../services/iptv_api_client.dart';
import '../widgets/tv_focus_wrapper.dart';
import 'tv_content_grid_screen.dart';
import 'tv_scaffold.dart';
import 'continue_watching_row.dart';
import 'tv_movie_details_screen.dart';

class TVHomeScreen extends StatefulWidget {
  const TVHomeScreen({super.key});

  @override
  State<TVHomeScreen> createState() => _TVHomeScreenState();
}

class _TVHomeScreenState extends State<TVHomeScreen> {
  final FocusNode _liveFocusNode = FocusNode();
  final FocusNode _moviesFocusNode = FocusNode();
  final FocusNode _seriesFocusNode = FocusNode();

  bool _isLoadingTopNew = true;
  List<StreamItem> _topNewMovies = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_liveFocusNode);
      _loadTopNewMovies2026();
    });
  }

  Future<void> _loadTopNewMovies2026() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final categories = await IptvApiClient.getCategories(auth.activeCode, 'get_vod_categories');
      CategoryItem? targetCat;
      for (var c in categories) {
        final name = c.categoryName.toUpperCase();
        if (name.contains('TOP NEW MOVIES 2026') || name.contains('2026') || name.contains('NEW MOVIES')) {
          targetCat = c;
          break;
        }
      }

      List<StreamItem> streams = [];
      if (targetCat != null) {
        streams = await IptvApiClient.getStreams(auth.activeCode, 'movies', targetCat.categoryId);
      }

      if (streams.isEmpty) {
        streams = await IptvApiClient.getStreams(auth.activeCode, 'movies', '');
      }

      if (mounted) {
        setState(() {
          _topNewMovies = streams.take(20).toList();
          _isLoadingTopNew = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingTopNew = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _liveFocusNode.dispose();
    _moviesFocusNode.dispose();
    _seriesFocusNode.dispose();
    super.dispose();
  }

  void _navigateToSection(String type, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => TVContentGridScreen(
          streamType: type,
          sectionTitle: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TVScaffold(
      showBackButton: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cinematic Ambient Glowing Gradients Background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.6),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.5),
                    const Color(0xFF0B0B0B),
                    const Color(0xFF050505),
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Dashboard Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 Massive Widescreen Glassmorphism Interactive Cards
                SizedBox(
                  height: 230,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(
                                height: 210,
                                child: _buildPrimaryDashboardCard(
                                  title: 'Live Channels',
                                  subtitle: 'قنوات البث المباشر',
                                  icon: Icons.tv,
                                  focusNode: _liveFocusNode,
                                  autofocus: true,
                                  onTap: () => _navigateToSection('live', 'Live Channels'),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(
                                height: 210,
                                child: _buildPrimaryDashboardCard(
                                  title: 'Movies',
                                  subtitle: 'الأفلام',
                                  icon: Icons.movie,
                                  focusNode: _moviesFocusNode,
                                  onTap: () => _navigateToSection('movies', 'Movies'),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(
                                height: 210,
                                child: _buildPrimaryDashboardCard(
                                  title: 'Series',
                                  subtitle: 'المسلسلات',
                                  icon: Icons.video_library,
                                  focusNode: _seriesFocusNode,
                                  onTap: () => _navigateToSection('series', 'Series'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Continue Watching Rows
                const TVContinueWatchingRow(sectionType: 'movies'),
                const TVContinueWatchingRow(sectionType: 'series'),
                const SizedBox(height: 16),

                // TOP NEW MOVIES 2026 Cinematic Horizontal Row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                      child: Row(
                        children: const [
                          Icon(Icons.local_fire_department, color: Color(0xFFE50914), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'TOP NEW MOVIES 2026 (أحدث أفلام 2026)',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 240,
                      child: _isLoadingTopNew
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                          : _topNewMovies.isEmpty
                              ? const Center(child: Text('No movies available in this category', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 36),
                                  itemCount: _topNewMovies.length,
                                  itemBuilder: (context, index) {
                                    final item = _topNewMovies[index];
                                    return _buildTrendingCard(item);
                                  },
                                ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'jokartv.com',
                        style: TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Version v1.0.0',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        '© 2026 Jokar TV. All rights reserved.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return TvFocusWrapper(
      autofocus: autofocus,
      focusNode: focusNode,
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFF141414).withOpacity(0.85),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: const Color(0xFFE50914)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingCard(StreamItem item) {
    return TvFocusWrapper(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<dynamic>(
            builder: (_) => TVMovieDetailsScreen(
              movieId: item.streamId,
              movieName: item.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
        ),
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
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }
}
