import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../generated/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _voiceEnabled = true;
  String _languageCode = 'en';
  bool _loading = true;

  static const Map<String, String> languages = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'bn': 'বাংলা (Bengali)',
    'mr': 'मराठी (Marathi)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'ml': 'മലയാളം (Malayalam)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'gu': 'ગુજરાતી (Gujarati)',
    'ur': 'اردو (Urdu)',
    'or': 'ଓଡିଆ (Odia)',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceEnabled = prefs.getBool('voice_enabled') ?? true;
      _languageCode = prefs.getString('language_code') ?? 'en';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', _voiceEnabled);
    await prefs.setString('language_code', _languageCode);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(t.voiceAssistant),
            value: _voiceEnabled,
            onChanged: (v) => setState(() => _voiceEnabled = v),
            subtitle: Text(t.voiceSubtitle),
          ),
          const SizedBox(height: 8),
          Text(t.language),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _languageCode,
            items: languages.entries
                .map((e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _languageCode = v ?? 'en'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(t.saveSettings),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await FirebaseAuth.instance.signOut();
                messenger.showSnackBar(SnackBar(content: Text(t.loggedOut)));
              } catch (_) {}
            },
            icon: const Icon(Icons.logout),
            label: Text(t.logout),
          ),
        ],
      ),
    );
  }
}


