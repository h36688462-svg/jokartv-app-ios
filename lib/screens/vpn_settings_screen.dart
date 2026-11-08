import 'package:flutter/material.dart';

class VpnSettingsScreen extends StatefulWidget {
  const VpnSettingsScreen({super.key});

  @override
  State<VpnSettingsScreen> createState() => _VpnSettingsScreenState();
}

class _VpnSettingsScreenState extends State<VpnSettingsScreen> {
  bool _vpnEnabled = false;
  String _selectedServer = 'USA - New York (Optimized for IPTV)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Built-in VPN Integration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  _vpnEnabled ? Icons.security : Icons.security_outlined,
                  size: 64,
                  color: _vpnEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _vpnEnabled ? 'VPN Connected & Secured' : 'VPN Disconnected',
                  style: TextStyle(
                    color: _vpnEnabled ? Colors.green : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bypass ISP throttling and geo-restrictions with our ultra-fast streaming VPN servers.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                SwitchListTile(
                  activeColor: const Color(0xFFE50914),
                  title: const Text('Enable VPN Protection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Auto-connect on app startup', style: TextStyle(color: Colors.grey)),
                  value: _vpnEnabled,
                  onChanged: (val) {
                    setState(() {
                      _vpnEnabled = val;
                    });
                  },
                ),
                const Divider(color: Colors.white10, height: 32),

                DropdownButtonFormField<String>(
                  value: _selectedServer,
                  dropdownColor: const Color(0xFF1F1F1F),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Select VPN Server Location',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1F1F1F),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: [
                    'USA - New York (Optimized for IPTV)',
                    'Germany - Frankfurt (Ultra Low Ping)',
                    'UK - London (High Speed Streaming)',
                    'Canada - Toronto (Secure Gateway)',
                    'Netherlands - Amsterdam (P2P & Stream Ready)',
                  ].map((server) => DropdownMenuItem(value: server, child: Text(server))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedServer = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vpnEnabled ? Colors.green : const Color(0xFFE50914),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _vpnEnabled = !_vpnEnabled;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_vpnEnabled ? 'VPN Connected Successfully!' : 'VPN Disconnected.')),
                      );
                    },
                    child: Text(
                      _vpnEnabled ? 'DISCONNECT VPN' : 'CONNECT VPN NOW',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
