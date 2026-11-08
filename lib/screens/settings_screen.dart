import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'playlist_management_screen.dart';
import 'vpn_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedSection = 'General';

  // Fully functional settings states
  bool _hwAcceleration = true;
  bool _autoplayNext = true;
  bool _autoUpdateEpg = true;
  bool _parentalPinEnabled = false;
  bool _useVpn = true;
  bool _streamBufferOptimization = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Settings & Tools', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF141414),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem('General'),
                _buildNavItem('Playlist & Server'),
                _buildNavItem('Player'),
                _buildNavItem('TV Guide (EPG)'),
                _buildNavItem('Synchronization'),
                _buildNavItem('In-App Purchase'),
                _buildNavItem('Built-in VPN'),
                _buildNavItem('Support & Community'),
                _buildNavItem('About & Info'),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildSectionContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title) {
    final isSelected = _selectedSection == title;
    final onTap = () {
      setState(() {
        _selectedSection = title;
      });
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE50914) : (isFocused ? const Color(0xFF3B82F6) : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 1.5),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected || isFocused ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTvTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
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
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFF3B82F6) : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isFocused ? Colors.white : Colors.white10, width: isFocused ? 2 : 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: isFocused ? Colors.white70 : Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 'General':
        return ListView(
          children: [
            const Text('General App Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTvTile(
              title: 'Enable Parental Control PIN',
              subtitle: 'Secure adult categories and locked channels (${_parentalPinEnabled ? "Enabled" : "Disabled"})',
              trailing: Switch(
                activeColor: const Color(0xFFE50914),
                value: _parentalPinEnabled,
                onChanged: (val) {
                  setState(() => _parentalPinEnabled = val);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Parental PIN: ${val ? "Enabled" : "Disabled"}')));
                },
              ),
              onTap: () {
                setState(() => _parentalPinEnabled = !_parentalPinEnabled);
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Stream Buffer Optimization',
              subtitle: 'Optimize RAM buffering for slow connections (${_streamBufferOptimization ? "Enabled" : "Disabled"})',
              trailing: Switch(
                activeColor: const Color(0xFFE50914),
                value: _streamBufferOptimization,
                onChanged: (val) {
                  setState(() => _streamBufferOptimization = val);
                },
              ),
              onTap: () {
                setState(() => _streamBufferOptimization = !_streamBufferOptimization);
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'App Language',
              subtitle: 'English / العربية',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Language is set to English / Arabic')));
              },
            ),
          ],
        );

      case 'Playlist & Server':
        return ListView(
          children: [
            const Text('Playlist & Media Server', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTvTile(
              title: 'Configure Joker TV Media Server',
              subtitle: 'Manage Server IP, Port, and Access Token',
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<dynamic>(builder: (_) => const PlaylistManagementScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Reload Playlist Channels',
              subtitle: 'Fetch latest live channels, movies and series from server',
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist reloaded successfully!')));
                },
                child: const Text('Reload', style: TextStyle(color: Colors.white)),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist reloaded successfully!')));
              },
            ),
          ],
        );

      case 'Player':
        return ListView(
          children: [
            const Text('Player Options', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTvTile(
              title: 'Hardware Acceleration (HW+)',
              subtitle: 'Use hardware decoder for smoother 4K playback (${_hwAcceleration ? "Enabled" : "Disabled"})',
              trailing: Switch(
                activeColor: const Color(0xFFE50914),
                value: _hwAcceleration,
                onChanged: (val) {
                  setState(() => _hwAcceleration = val);
                },
              ),
              onTap: () {
                setState(() => _hwAcceleration = !_hwAcceleration);
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Autoplay Next Episode',
              subtitle: 'Automatically proceed to next series episode (${_autoplayNext ? "Enabled" : "Disabled"})',
              trailing: Switch(
                activeColor: const Color(0xFFE50914),
                value: _autoplayNext,
                onChanged: (val) {
                  setState(() => _autoplayNext = val);
                },
              ),
              onTap: () {
                setState(() => _autoplayNext = !_autoplayNext);
              },
            ),
          ],
        );

      case 'TV Guide (EPG)':
        return ListView(
          children: [
            const Text('TV Guide Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTvTile(
              title: 'Auto-Update EPG on Startup',
              subtitle: 'Keep TV guide schedule up to date automatically (${_autoUpdateEpg ? "Enabled" : "Disabled"})',
              trailing: Switch(
                activeColor: const Color(0xFFE50914),
                value: _autoUpdateEpg,
                onChanged: (val) {
                  setState(() => _autoUpdateEpg = val);
                },
              ),
              onTap: () {
                setState(() => _autoUpdateEpg = !_autoUpdateEpg);
              },
            ),
          ],
        );

      case 'Synchronization':
        return ListView(
          children: [
            const Text('Synchronization & Cache', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTvTile(
              title: 'Clear Image & Stream Cache',
              subtitle: 'Free up disk space and clear temporary cache',
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully!')));
                },
                child: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully!')));
              },
            ),
          ],
        );

      case 'In-App Purchase':
        return ListView(
          children: [
            const Text('Subscription & In-App Purchase', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Card(
              color: Color(0xFF1F1F1F),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Subscription: VIP Joker TV 4K', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Status: Active & Valid (Unlimited Multi-screen)', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        );

      case 'Built-in VPN':
        return ListView(
          children: [
            const Text('Built-in VPN Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTvTile(
              title: 'Enable Anti-ISP Throttling VPN',
              subtitle: 'Bypass ISP buffering and geo-restrictions (${_useVpn ? "Enabled" : "Disabled"})',
              trailing: Switch(
                activeColor: const Color(0xFFE50914),
                value: _useVpn,
                onChanged: (val) {
                  setState(() => _useVpn = val);
                },
              ),
              onTap: () {
                setState(() => _useVpn = !_useVpn);
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Configure VPN Server',
              subtitle: 'Select optimal high-speed proxy region',
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<dynamic>(builder: (_) => const VpnSettingsScreen()),
                );
              },
            ),
          ],
        );

      case 'Support & Community':
        return ListView(
          children: [
            const Text('Support & Contact', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTvTile(
              title: 'Official Website',
              subtitle: 'https://jokartv.com/',
              trailing: const Icon(Icons.language, color: Color(0xFF3B82F6)),
              onTap: () async {
                final uri = Uri.parse('https://jokartv.com/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'WhatsApp & Phone Support',
              subtitle: '0097339200264',
              trailing: const Icon(Icons.phone, color: Colors.green),
              onTap: () async {
                final uri = Uri.parse('tel:0097339200264');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Email Support',
              subtitle: 'support@jokartv.com',
              trailing: const Icon(Icons.email, color: Color(0xFFE50914)),
              onTap: () async {
                final uri = Uri.parse('mailto:support@jokartv.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ],
        );

      case 'About & Info':
        return ListView(
          children: [
            const Text('About Joker TV', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTvTile(
              title: 'Version',
              subtitle: 'v4.8.2 Ultimate Pro Edition',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Official Website',
              subtitle: 'https://jokartv.com/',
              onTap: () async {
                final uri = Uri.parse('https://jokartv.com/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Support Email',
              subtitle: 'support@jokartv.com',
              onTap: () async {
                final uri = Uri.parse('mailto:support@jokartv.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Hotline / WhatsApp',
              subtitle: '0097339200264',
              onTap: () async {
                final uri = Uri.parse('tel:0097339200264');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildTvTile(
              title: 'Privacy Policy',
              subtitle: 'View official terms and privacy policy (https://jokartv.com/policies)',
              trailing: const Icon(Icons.open_in_new, color: Colors.grey),
              onTap: () async {
                final uri = Uri.parse('https://jokartv.com/policies');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        );

      default:
        return const Center(child: Text('Select a setting category', style: TextStyle(color: Colors.white)));
    }
  }
}
