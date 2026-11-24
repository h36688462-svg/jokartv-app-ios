import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/iptv_provider.dart';
import '../services/iptv_api_client.dart';
import 'tv_scaffold.dart';

class TVSettingsScreen extends StatefulWidget {
  const TVSettingsScreen({super.key});

  @override
  State<TVSettingsScreen> createState() => _TVSettingsScreenState();
}

class _TVSettingsScreenState extends State<TVSettingsScreen> {
  int _selectedCategoryIndex = 0;
  bool _hardwareAcceleration = true;
  String _defaultFormat = 'TS (.ts / .m3u8)';
  String _selectedLanguage = 'English';
  final FocusNode _firstSettingFocusNode = FocusNode();

  final List<String> _categories = [
    'General',
    'Playback',
    'Audio / Video',
    'Language',
    'Media Server',
    'About',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_firstSettingFocusNode);
    });
  }

  @override
  void dispose() {
    _firstSettingFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshPlaylist(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final iptv = Provider.of<IptvProvider>(context, listen: false);
    IptvApiClient.clearCache();
    await iptv.loadData(auth.activeCode);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist refreshed successfully from server!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TVScaffold(
      title: 'Settings',
      child: Row(
        children: [
          // Left Sidebar: Categories
          Container(
            width: 280,
            color: const Color(0xFF141414),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Preferences',
                    style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return _buildCategoryTile(_categories[index], index, isSelected);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Panel: Interactive Options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _categories[_selectedCategoryIndex],
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: _buildSettingsContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String title, int index, bool isSelected) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : (isFocused ? const Color(0xFF1E293B) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedCategoryIndex = index),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected || isFocused ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: isSelected || isFocused ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildSettingsContent() {
    switch (_selectedCategoryIndex) {
      case 0: // General
        return ListView(
          children: [
            _buildToggleOption('Auto Start on Boot', true, (val) {}),
            const Divider(color: Colors.white10),
            _buildToggleOption('Parental Control PIN Protection', false, (val) {}),
          ],
        );
      case 1: // Playback
        return ListView(
          children: [
            _buildToggleOption('Hardware Acceleration (تسريع عتادي)', _hardwareAcceleration, (val) {
              setState(() => _hardwareAcceleration = val);
            }),
            const Divider(color: Colors.white10),
            _buildDropdownOption('Default Stream Format', _defaultFormat, ['TS (.ts / .m3u8)', 'HLS', 'MP4'], (val) {
              if (val != null) setState(() => _defaultFormat = val);
            }),
            const Divider(color: Colors.white10),
            _buildDropdownOption('Buffer Size', 'Normal (30s)', ['Low (10s)', 'Normal (30s)', 'High (60s)'], (val) {}),
          ],
        );
      case 2: // Audio/Video
        return ListView(
          children: [
            _buildToggleOption('Volume Boost (معزز الصوت)', true, (val) {}),
            const Divider(color: Colors.white10),
            _buildToggleOption('Cinematic Lighting', false, (val) {}),
          ],
        );
      case 3: // Language
        return ListView(
          children: [
            _buildDropdownOption('App Language (اللغة)', _selectedLanguage, ['English', 'العربية'], (val) {
              if (val != null) setState(() => _selectedLanguage = val);
            }),
          ],
        );
      case 4: // Media Server
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Media Server Connection',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Server: http://169.58.114.30:8080',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _refreshPlaylist(context),
                child: const Text('Refresh Playlist / Update Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      case 5: // About
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'smartiptv_source/app/src/main/res/drawable/app_logo.png',
                  height: 70,
                  width: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv, size: 60, color: Color(0xFFE50914)),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Jokar TV', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('jokartv.com', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Version v1.0.0', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 12),
            const Text('© 2026 Jokar TV. All rights reserved.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        );
    }
  }

  Widget _buildToggleOption(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF3B82F6),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownOption(String title, String currentVal, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          DropdownButton<String>(
            value: currentVal,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 2, color: const Color(0xFF3B82F6)),
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
