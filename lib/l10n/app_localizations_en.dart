// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KaamBolo Mobile';

  @override
  String get navHome => 'Home';

  @override
  String get navPost => 'Post';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginTitle => 'Login with Phone OTP';

  @override
  String get phonePlaceholder => 'Phone number (e.g. +91XXXXXXXXXX)';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get verifyContinue => 'Verify & Continue';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get voiceAssistant => 'Voice Assistant (KaamBolo Mitra)';

  @override
  String get voiceSubtitle => 'Enable mic-based assistant';

  @override
  String get language => 'Language';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get logout => 'Logout';

  @override
  String get loggedOut => 'Logged out';

  @override
  String get settingsSaved => 'Settings saved';
}
