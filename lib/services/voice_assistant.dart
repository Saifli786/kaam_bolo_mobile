import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef VoiceCommandHandler = void Function(String text);

class VoiceAssistant {
  VoiceAssistant._();
  static final instance = VoiceAssistant._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _available = false;

  Future<void> init({String? languageCode}) async {
    _available = await _speech.initialize();
    if (languageCode != null) {
      await _tts.setLanguage(languageCode);
    }
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<bool> startListening(VoiceCommandHandler onResult, {String localeId = 'en_US'}) async {
    if (!_available) {
      _available = await _speech.initialize();
      if (!_available) return false;
    }
    final ok = await _speech.listen(
      onResult: (r) {
        if (r.recognizedWords.isNotEmpty && r.finalResult) {
          onResult(r.recognizedWords);
        }
      },
      localeId: localeId,
      listenMode: stt.ListenMode.search,
    );
    return ok;
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}


