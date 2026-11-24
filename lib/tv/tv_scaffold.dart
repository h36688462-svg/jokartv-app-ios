import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tv_profile_screen.dart';
import 'tv_settings_screen.dart';

class TVScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showHeader;
  final bool showBackButton;

  const TVScaffold({
    super.key,
    required this.child,
    this.title = 'JOKAR TV',
    this.showHeader = true,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.escape ||
                key == LogicalKeyboardKey.goBack ||
                key == LogicalKeyboardKey.browserBack) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0B0B),
          body: SafeArea(
            child: Column(
              children: [
                if (showHeader) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    color: const Color(0xFF111111),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Persistent Top-Left Branding & Back Button
                        Row(
                          children: [
                            if (showBackButton) ...[
                              _buildHeaderIconButton(
                                context,
                                icon: Icons.arrow_back,
                                tooltip: 'Back',
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 20),
                            ],
                            Image.asset(
                              'smartiptv_source/app/src/main/res/drawable/app_logo.png',
                              height: 42,
                              width: 42,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv, color: Color(0xFFE50914), size: 36),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),

                        // Persistent Top-Right Profile & Settings Icons
                        Row(
                          children: [
                            _buildHeaderIconButton(
                              context,
                              icon: Icons.account_circle,
                              tooltip: 'Profile (الملف الشخصي)',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<dynamic>(builder: (_) => const TVProfileScreen()),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildHeaderIconButton(
                              context,
                              icon: Icons.settings,
                              tooltip: 'Settings (الإعدادات)',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<dynamic>(builder: (_) => const TVSettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                ],
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: isFocused ? Matrix4.diagonal3Values(1.12, 1.12, 1.0) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFocused ? const Color(0xFF3B82F6) : const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(
                color: isFocused ? Colors.white : Colors.transparent,
                width: isFocused ? 2.5 : 0,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
