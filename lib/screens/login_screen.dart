import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/tv_keyboard_fix_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _code = '';

  void _appendChar(String char) {
    setState(() {
      _code += char;
    });
  }

  void _backspace() {
    if (_code.isNotEmpty) {
      setState(() {
        _code = _code.substring(0, _code.length - 1);
      });
    }
  }

  void _clear() {
    setState(() {
      _code = '';
    });
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    final code = _code.trim();
    if (code.isNotEmpty) {
      await authProvider.loginWithCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final keys = [
      ['1', '2', '3', '4', '5'],
      ['6', '7', '8', '9', '0'],
      ['A', 'B', 'C', 'D', 'E'],
      ['F', 'G', 'H', 'I', 'J'],
      ['K', 'L', 'M', 'N', 'O'],
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: TVKeyboardFixWrapper(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Logo / Title
                  Image.asset(
                    'smartiptv_source/app/src/main/res/drawable/app_logo.png',
                    height: 60,
                    cacheWidth: 300,
                    cacheHeight: 300,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'JOKER TV',
                        style: TextStyle(
                          color: Color(0xFFE50914),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter Activation Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use TV Remote D-Pad & OK button to select characters',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Code Display Box
                  Container(
                    width: double.infinity,
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE50914), width: 2),
                    ),
                    child: Text(
                      _code.isEmpty ? '--- --- --- ---' : _code,
                      style: TextStyle(
                        color: _code.isEmpty ? Colors.grey : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error Message
                  if (authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // On-Screen D-Pad Keypad Grid
                  ...keys.map((row) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row.map((char) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: SizedBox(
                                  width: 55,
                                  height: 45,
                                  child: _buildKeyButton(char, () => _appendChar(char)),
                                ),
                              )).toList(),
                        ),
                      )),

                  const SizedBox(height: 8),

                  // Action Row: Backspace, Clear, Submit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 45,
                        child: _buildKeyButton('⌫', _backspace, color: const Color(0xFF333333)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        height: 45,
                        child: _buildKeyButton('CLR', _clear, color: const Color(0xFF333333)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        height: 45,
                        child: FocusableActionDetector(
                          actions: <Type, Action<Intent>>{
                            ActivateIntent: CallbackAction<ActivateIntent>(
                              onInvoke: (Intent intent) {
                                _handleLogin(authProvider);
                                return null;
                              },
                            ),
                          },
                          child: Builder(
                            builder: (context) {
                              final isFocused = Focus.of(context).hasFocus;
                              return InkWell(
                                onTap: authProvider.isLoading ? null : () => _handleLogin(authProvider),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isFocused ? const Color(0xFF3B82F6) : const Color(0xFFE50914),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 2),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'SIGN IN',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyButton(String label, VoidCallback onPressed, {Color color = const Color(0xFF1F1F1F)}) {
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFF3B82F6) : color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFocused ? Colors.white : Colors.white24,
                  width: isFocused ? 2 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: label.length > 1 ? 13 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
