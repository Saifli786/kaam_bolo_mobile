import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/post_job_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

import 'firebase_options.dart';

bool _isFirebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
  } catch (_) {
    // Firebase will be initialized once configuration files are added.
    _isFirebaseInitialized = false;
  }
  runApp(KaamBoloApp(isFirebaseInitialized: _isFirebaseInitialized));
}

class KaamBoloApp extends StatefulWidget {
  final bool isFirebaseInitialized;
  const KaamBoloApp({super.key, required this.isFirebaseInitialized});

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
      locale: Locale(_languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('ta'),
        Locale('te'),
        Locale('bn'),
        Locale('mr'),
        Locale('pa'),
        Locale('ml'),
        Locale('kn'),
        Locale('gu'),
        Locale('ur'),
        Locale('or'),
      ],
      home: !widget.isFirebaseInitialized
          ? const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Firebase is not configured.\nPlease run "flutterfire configure" in the terminal and restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              ),
            )
          : StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) {
            return const _PhoneAuthScaffold();
          }
          final t = AppLocalizations.of(context);
          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: [
                NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t.navHome),
                NavigationDestination(icon: const Icon(Icons.post_add_outlined), selectedIcon: const Icon(Icons.post_add), label: t.navPost),
                NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: t.navProfile),
                NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: t.navSettings),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: _PhoneAuthForm(),
            ),
          ),
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
  ConfirmationResult? _confirmationResult;
  bool _sendingCode = false;
  bool _verifying = false;
  String? _error;

  String _formatPhoneNumber(String input) {
    String phone = input.trim();
    if (phone.isEmpty) return phone;
    // Strip non-numeric characters for simple validation, except '+'
    if (!phone.startsWith('+')) {
      if (phone.length == 10) {
        phone = '+91$phone';
      } else {
        phone = '+$phone';
      }
    }
    return phone;
  }

  Future<void> _sendCode() async {
    final formattedPhone = _formatPhoneNumber(_phoneController.text);
    if (formattedPhone.length < 10) {
      setState(() => _error = 'Please enter a valid phone number');
      return;
    }

    setState(() {
      _sendingCode = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        _confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(formattedPhone);
        setState(() {
          _verificationId = 'web-verification'; // Just a flag to show the OTP field
        });
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: formattedPhone,
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
            setState(() => _error = e.message ?? 'Verification failed');
          },
          codeAutoRetrievalTimeout: (verificationId) {
            setState(() => _verificationId = verificationId);
          },
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().contains('message') ? e.toString() : 'Failed to send code');
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
      final smsCode = _codeController.text.trim();
      if (kIsWeb && _confirmationResult != null) {
        await _confirmationResult!.confirm(smsCode);
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      setState(() => _error = 'Invalid code or verification failed');
    } finally {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white.withOpacity(0.95),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.work_outline, size: 64, color: Color(0xFFFF6F00)),
                const SizedBox(height: 16),
                Text(
                  t.loginTitle, 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  "Find your next job with your voice",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16, letterSpacing: 1.5),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(color: Colors.black87, fontSize: 16, letterSpacing: 1.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelText: t.phonePlaceholder,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _sendingCode ? null : _sendCode,
                    child: _sendingCode 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : Text(t.sendOtp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (_verificationId != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      labelText: t.enterOtp,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _verifying ? null : _verifyCode,
                      child: _verifying 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : Text(t.verifyContinue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
