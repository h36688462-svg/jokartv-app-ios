import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/ios_media_source_screen.dart';
import 'tv_scaffold.dart';

class TVProfileScreen extends StatefulWidget {
  const TVProfileScreen({super.key});

  @override
  State<TVProfileScreen> createState() => _TVProfileScreenState();
}

class _TVProfileScreenState extends State<TVProfileScreen> {
  final FocusNode _logoutFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_logoutFocusNode);
    });
  }

  @override
  void dispose() {
    _logoutFocusNode.dispose();
    super.dispose();
  }

  void _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<dynamic>(builder: (_) => const IosMediaSourceScreen()),
        (route) => false,
      );
    }
  }

  String _formatExpDate(dynamic rawExp) {
    if (rawExp == null) return 'Active (Unlimited)';
    if (rawExp is int) {
      if (rawExp <= 0) return 'Unlimited / Lifetime';
      final dt = DateTime.fromMillisecondsSinceEpoch(rawExp * 1000);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    final str = rawExp.toString();
    if (str.toLowerCase() == 'unlimited' || str.isEmpty) return 'Active (Unlimited)';
    final intVal = int.tryParse(str);
    if (intVal != null && intVal > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userInfo = auth.userInfo ?? {};
    final username = userInfo['username']?.toString() ?? auth.activeCode;
    final status = userInfo['status']?.toString() ?? 'Active';
    final rawExp = userInfo['exp_date'];
    final expDate = _formatExpDate(rawExp);
    final maxConns = userInfo['max_connections']?.toString() ?? '1';
    final activeConns = userInfo['active_cons']?.toString() ?? '1';
    final serverUrl = userInfo['server_url']?.toString() ?? 'http://169.58.114.30:8080';

    return TVScaffold(
      title: 'User Profile & Account Info',
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Details Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    // Avatar / Icon
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE50914), width: 3),
                      ),
                      child: const Icon(Icons.person, size: 80, color: Colors.white70),
                    ),
                    const SizedBox(width: 48),

                    // Info Columns
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoRow('Username / Code:', username),
                          const SizedBox(height: 16),
                          _buildInfoRow('Account Status:', status, isBadge: true),
                          const SizedBox(height: 16),
                          _buildInfoRow('Server URL:', serverUrl),
                          const SizedBox(height: 16),
                          _buildInfoRow('Subscription Expiration:', expDate),
                          const SizedBox(height: 16),
                          _buildInfoRow('Max Allowed Connections:', maxConns),
                          const SizedBox(height: 16),
                          _buildInfoRow('Active Connections:', activeConns),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            Center(
              child: SizedBox(
                width: 350,
                height: 55,
                child: Focus(
                  focusNode: _logoutFocusNode,
                  child: Builder(
                    builder: (context) {
                      final isFocused = Focus.of(context).hasFocus;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: isFocused ? Matrix4.diagonal3Values(1.05, 1.05, 1.0) : Matrix4.identity(),
                        transformAlignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isFocused ? const Color(0xFF3B82F6) : const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 3),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withOpacity(0.6),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  )
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleLogout(context),
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(
                              child: Text(
                                'Logout / Change Media Source',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBadge = false}) {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        isBadge
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              )
            : Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
      ],
    );
  }
}
