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

  Future<void> _handleSampleStream(AuthProvider auth) async {
    await auth.loginWithSampleStream();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Jokar TV - Personal Media Player (BYOC)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tv_rounded, size: 56, color: Color(0xFFE50914)),
                  const SizedBox(height: 16),
                  const Text(
                    'Bring Your Own Content (BYOC)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your personal M3U Playlist or Server API credentials to start streaming.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Prominent Test Sample Stream Button (Guideline 2.5.19 friendly)
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB80710)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: auth.isLoading ? null : () => _handleSampleStream(auth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Test Sample Stream',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR CONFIGURE SOURCE', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 20),

                  if (auth.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(
                    height: 260,
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
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFF1F1F1F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _m3uUrlController,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'M3U Playlist URL (.m3u / .m3u8)',
                                  hintText: 'https://example.com/playlist.m3u',
                                  hintStyle: const TextStyle(color: Colors.white24),
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFF1F1F1F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: auth.isLoading ? null : () => _handleM3uLogin(auth),
                                  child: auth.isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Connect M3U Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFF1F1F1F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _serverUrlController,
                                keyboardType: TextInputType.url,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Server URL (e.g. http://portal.com:8080)',
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFF1F1F1F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                                        labelStyle: const TextStyle(color: Colors.grey),
                                        filled: true,
                                        fillColor: const Color(0xFF1F1F1F),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                                        labelStyle: const TextStyle(color: Colors.grey),
                                        filled: true,
                                        fillColor: const Color(0xFF1F1F1F),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: auth.isLoading ? null : () => _handleServerLogin(auth),
                                  child: auth.isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Login to Server', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Version 1.0.0+30 • 100% Compliant Personal Media Player',
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
