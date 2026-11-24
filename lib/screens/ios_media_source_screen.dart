import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../models/iptv_models.dart';

class IosMediaSourceScreen extends StatefulWidget {
  const IosMediaSourceScreen({super.key});

  @override
  State<IosMediaSourceScreen> createState() => _IosMediaSourceScreenState();
}

class _IosMediaSourceScreenState extends State<IosMediaSourceScreen> {
  int _selectedMode = 0; // 0 for M3U URL, 1 for Server Login

  // Mode 1: M3U
  final TextEditingController _m3uNameController = TextEditingController(text: 'My M3U Playlist');
  final TextEditingController _m3uUrlController = TextEditingController();

  // Mode 2: Server Login
  final TextEditingController _serverNameController = TextEditingController(text: 'Media Server');
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _serverUserController = TextEditingController();
  final TextEditingController _serverPassController = TextEditingController();

  bool _obscurePassword = true;
  List<UserAccount> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final accounts = await StorageService.getSavedAccounts();
    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
      });
    }
  }

  @override
  void dispose() {
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
    await StorageService.addAccount(UserAccount(
      name: name.isEmpty ? 'My M3U Playlist' : name,
      url: url,
      username: 'm3u',
      password: 'm3u',
    ));
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
    await StorageService.addAccount(UserAccount(
      name: name.isEmpty ? 'Media Server' : name,
      url: url,
      username: user,
      password: pass,
    ));
    await auth.loginWithServer(name, url, user, pass);
  }

  Future<void> _loadProfile(UserAccount account, AuthProvider auth) async {
    if (account.username == 'm3u') {
      setState(() => _selectedMode = 0);
      _m3uNameController.text = account.name;
      _m3uUrlController.text = account.url;
      await auth.loginWithM3U(account.name, account.url);
    } else {
      setState(() => _selectedMode = 1);
      _serverNameController.text = account.name;
      _serverUrlController.text = account.url;
      _serverUserController.text = account.username;
      _serverPassController.text = account.password;
      await auth.loginWithServer(account.name, account.url, account.username, account.password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 820),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: isLandscape
                    ? Row(
                        children: [
                          // Left Panel: Form & Inputs
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildFormContent(auth),
                            ),
                          ),
                          // Right Panel: Branded Showcase
                          Expanded(
                            flex: 4,
                            child: Container(
                              color: const Color(0xFF1A1A1A),
                              padding: const EdgeInsets.all(24.0),
                              child: _buildBrandedShowcase(),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: _buildBrandedShowcase(isCompact: true),
                          ),
                          const Divider(height: 1, color: Colors.white10),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: _buildFormContent(auth),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandedShowcase({bool isCompact = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'smartiptv_source/app/src/main/res/drawable/app_logo.png',
          height: isCompact ? 48 : 72,
          width: isCompact ? 48 : 72,
          cacheWidth: 200,
          cacheHeight: 200,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv_rounded, size: 64, color: Color(0xFFE50914)),
        ),
        SizedBox(height: isCompact ? 8 : 16),
        const Text(
          'Jokar TV',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormContent(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter Login Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),

        // Quick Saved Profiles Selector (if available)
        if (_savedAccounts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserAccount>(
                dropdownColor: const Color(0xFF1F1F1F),
                hint: const Text('Quick Select Saved Profile', style: TextStyle(color: Colors.grey, fontSize: 13)),
                isExpanded: true,
                items: _savedAccounts.map((acc) {
                  return DropdownMenuItem<UserAccount>(
                    value: acc,
                    child: Text(acc.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  );
                }).toList(),
                onChanged: (acc) {
                  if (acc != null) {
                    _loadProfile(acc, auth);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Clean Full-Width Equal-Width Mode Buttons
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedMode = 0),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedMode == 0 ? const Color(0xFFE50914) : const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedMode == 0 ? const Color(0xFFE50914) : Colors.white12),
                  ),
                  child: const Text(
                    'M3U URL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedMode = 1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedMode == 1 ? const Color(0xFFE50914) : const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedMode == 1 ? const Color(0xFFE50914) : Colors.white12),
                  ),
                  child: const Text(
                    'Server Login',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (auth.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              auth.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

        // Mode Form Fields
        if (_selectedMode == 0) ...[
          TextField(
            controller: _m3uNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Playlist Name',
              prefixIcon: const Icon(Icons.bookmark_outline, color: Colors.grey, size: 20),
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _m3uUrlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'M3U Playlist URL',
              hintText: 'https://example.com/playlist.m3u',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
              prefixIcon: const Icon(Icons.link_rounded, color: Colors.grey, size: 20),
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
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
                backgroundColor: const Color(0xFFE50914),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: auth.isLoading ? null : () => _handleM3uLogin(auth),
              child: auth.isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Connect M3U Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ] else ...[
          TextField(
            controller: _serverNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Profile Name',
              prefixIcon: const Icon(Icons.person_outline, color: Colors.grey, size: 20),
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _serverUrlController,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Server URL (http://portal.com:8080)',
              prefixIcon: const Icon(Icons.dns_outlined, color: Colors.grey, size: 20),
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _serverUserController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.badge_outlined, color: Colors.grey, size: 18),
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF1F1F1F),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _serverPassController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF1F1F1F),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 18),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: auth.isLoading ? null : () => _handleServerLogin(auth),
              child: auth.isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Login to Server', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ],
    );
  }
}
