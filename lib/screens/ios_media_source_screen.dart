import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class IosMediaSourceScreen extends StatefulWidget {
  const IosMediaSourceScreen({super.key});

  @override
  State<IosMediaSourceScreen> createState() => _IosMediaSourceScreenState();
}

class _IosMediaSourceScreenState extends State<IosMediaSourceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mode 1: M3U
  final TextEditingController _m3uNameController = TextEditingController(text: 'My M3U Playlist');
  final TextEditingController _m3uUrlController = TextEditingController();

  // Mode 2: Server Login
  final TextEditingController _serverNameController = TextEditingController(text: 'Media Server');
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _serverUserController = TextEditingController();
  final TextEditingController _serverPassController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _m3uNameController.dispose();
    _m3uUrlController.dispose();
    _serverNameController.dispose();
    _serverUrlController.dispose();
    _serverUserController.dispose();
    _serverPassController.dispose();
    super.dispose();
  }

  Future<void> _handleM3uLogin(AuthProvider auth) async {
    final name = _m3uNameController.text.trim();
    final url = _m3uUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid M3U playlist URL')),
      );
      return;
    }
    await auth.loginWithM3U(name, url);
  }

  Future<void> _handleServerLogin(AuthProvider auth) async {
    final name = _serverNameController.text.trim();
    final url = _serverUrlController.text.trim();
    final user = _serverUserController.text.trim();
    final pass = _serverPassController.text.trim();

    if (url.isEmpty || user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Server URL, Username, and Password')),
      );
      return;
    }
    await auth.loginWithServer(name, url, user, pass);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Jokar TV',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Logo Asset
                  Image.asset(
                    'smartiptv_source/app/src/main/res/drawable/app_logo.png',
                    height: 48,
                    width: 48,
                    cacheWidth: 150,
                    cacheHeight: 150,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv_rounded, size: 48, color: Color(0xFFE50914)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add Media Source',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your M3U playlist URL or server login details.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // TabBar for Dual Modes
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'M3U Playlist URL'),
                        Tab(text: 'Server Login'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (auth.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(
                    height: 220,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _m3uNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Playlist Name (Optional)',
                                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFF1F1F1F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _m3uUrlController,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'M3U Playlist URL (.m3u / .m3u8)',
                                  hintText: 'https://example.com/playlist.m3u',
                                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFF1F1F1F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: auth.isLoading ? null : () => _handleM3uLogin(auth),
                                  child: auth.isLoading
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Connect M3U Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _serverNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Profile Name',
                                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFF1F1F1F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _serverUrlController,
                                keyboardType: TextInputType.url,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Server URL (e.g. http://portal.com:8080)',
                                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFF1F1F1F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _serverUserController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Username',
                                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                        filled: true,
                                        fillColor: const Color(0xFF1F1F1F),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _serverPassController,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                        filled: true,
                                        fillColor: const Color(0xFF1F1F1F),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: auth.isLoading ? null : () => _handleServerLogin(auth),
                                  child: auth.isLoading
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Login to Server', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Version 1.0.0+30',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
