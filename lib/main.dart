import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/post_job_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase will be initialized once configuration files are added.
  }
  runApp(const KaamBoloApp());
}

class KaamBoloApp extends StatefulWidget {
  const KaamBoloApp({super.key});

  @override
  State<KaamBoloApp> createState() => _KaamBoloAppState();
}

class _KaamBoloAppState extends State<KaamBoloApp> {
  int _selectedIndex = 0;
  bool _voiceEnabled = true;
  String _languageCode = 'en';
  bool _prefsLoaded = false;

  final _screens = const [
    HomeScreen(),
    PostJobScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceEnabled = prefs.getBool('voice_enabled') ?? true;
      _languageCode = prefs.getString('language_code') ?? 'en';
      _prefsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6F00),
      brightness: Brightness.light,
    );

    final theme = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      textTheme: GoogleFonts.notoSansTextTheme(),
      useMaterial3: true,
    );

    if (!_prefsLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KaamBolo Mobile',
      theme: theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) {
            return const _PhoneAuthScaffold();
          }
          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.post_add_outlined), selectedIcon: Icon(Icons.post_add), label: 'Post'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PhoneAuthScaffold extends StatelessWidget {
  const _PhoneAuthScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: _PhoneAuthForm(),
        ),
      ),
    );
  }
}

class _PhoneAuthForm extends StatefulWidget {
  const _PhoneAuthForm();

  @override
  State<_PhoneAuthForm> createState() => _PhoneAuthFormState();
}

class _PhoneAuthFormState extends State<_PhoneAuthForm> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _verificationId;
  bool _sendingCode = false;
  bool _verifying = false;
  String? _error;

  Future<void> _sendCode() async {
    setState(() {
      _sendingCode = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } catch (_) {}
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        verificationFailed: (e) {
          setState(() => _error = e.message);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      setState(() => _error = 'Failed to send code');
    } finally {
      setState(() => _sendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() => _error = 'Invalid code');
    } finally {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Login with Phone OTP', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Phone number (e.g. +91XXXXXXXXXX)',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sendingCode ? null : _sendCode,
              child: _sendingCode ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send OTP'),
            ),
            if (_verificationId != null) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter OTP',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _verifying ? null : _verifyCode,
                child: _verifying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Verify & Continue'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
