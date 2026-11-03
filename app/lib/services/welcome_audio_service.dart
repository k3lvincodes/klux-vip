import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing the one-time VIP welcome audio greeting.
///
/// Complies strictly with the requirement:
///   - Plays `assets/audio/welcome_vip.mp3` once on the first time the user opens the app.
///   - Persists state in [SharedPreferences] to ensure it never repeats on subsequent launches.
///   - Fails silently with zero disruptions to UI/navigation if device audio is muted or unavailable.
class WelcomeAudioService {
  static const String _hasPlayedKey = 'has_played_welcome_vip_audio_v1';
  static AudioPlayer? _activePlayer;

  /// Checks if the welcome audio has already been played.
  /// If not, marks it as played immediately and begins playback.
  static Future<void> playWelcomeIfFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPlayed = prefs.getBool(_hasPlayedKey) ?? false;
      if (hasPlayed) return;

      // Mark as played immediately to prevent race conditions or double plays
      await prefs.setBool(_hasPlayedKey, true);

      // Small delay so audio starts gently alongside the visual entrance
      await Future.delayed(const Duration(milliseconds: 350));

      final player = AudioPlayer();
      _activePlayer = player;

      await player.setVolume(1.0);
      await player.setReleaseMode(ReleaseMode.stop);

      // audioplayers loads from 'assets/' by default; AssetSource('audio/welcome_vip.mp3')
      // resolves to 'assets/audio/welcome_vip.mp3'
      await player.play(AssetSource('audio/welcome_vip.mp3'));

      player.onPlayerComplete.listen((_) {
        try {
          player.dispose();
          if (_activePlayer == player) _activePlayer = null;
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('WelcomeAudioService: playback skipped or failed: $e');
    }
  }

  /// Optional debug helper to reset the first-launch playback flag
  static Future<void> resetFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasPlayedKey);
  }
}

