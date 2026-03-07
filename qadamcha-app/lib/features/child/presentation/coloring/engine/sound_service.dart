import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:shared_preferences/shared_preferences.dart';

/// O'yin uchun ovoz effektlarini boshqarish xizmati.
///
/// BG musiqa: `just_audio` paketi — alohida audio session,
///            audioplayers bilan to'qnashmaydi.
/// SFX:       `audioplayers` paketi — lowLatency (SoundPool),
///            qisqa ovozlar uchun.
class SoundService {
  /// Singleton
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // ═══ SFX: audioplayers (SoundPool) ═══
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // ═══ BG MUSIQA: just_audio (audio interruption'larni IGNORE qiladi) ═══
  final just_audio.AudioPlayer _bgPlayer = just_audio.AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
    androidApplyAudioAttributes: false,
  );
  bool _bgShouldPlay = false;

  // ═══ INTRO OVOZ: just_audio (alohida player) ═══
  just_audio.AudioPlayer? _introPlayer;

  // Volume sozlamalari (0.0 — 1.0)
  double _bgVolume = 0.30;
  double _sfxVolume = 0.90;

  /// Volume getter'lar
  double get bgVolume => _bgVolume;
  double get sfxVolume => _sfxVolume;

  static const _bgVolumeKey = 'coloring_bg_volume';
  static const _sfxVolumeKey = 'coloring_sfx_volume';

  bool _isInit = false;

  /// Initialization — faqat bir marta chaqiriladi
  Future<void> init() async {
    if (_isInit) return;
    try {
      // SharedPreferences dan saqlangan volume'larni yuklash
      final prefs = await SharedPreferences.getInstance();
      _bgVolume = prefs.getDouble(_bgVolumeKey) ?? 0.30;
      _sfxVolume = prefs.getDouble(_sfxVolumeKey) ?? 0.90;

      // SFX player — lowLatency (SoundPool), audio focus so'ramaydi
      await _sfxPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          audioMode: AndroidAudioMode.normal,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ));
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(_sfxVolume);

      // BG musiqa — just_audio bilan (volume faqat)
      await _bgPlayer.setVolume(_bgVolume);

      _isInit = true;
      debugPrint('🔊 SoundService initialized');
    } catch (e) {
      debugPrint('🔇 SoundService init error: $e');
    }
  }

  // ═══════════════════════════════════════
  // BACKGROUND MUSIQA (just_audio)
  // ═══════════════════════════════════════

  /// Bo'yash ekranida background musiqa boshlash (loop)
  Future<void> playBgMusic() async {
    if (_bgShouldPlay) return;
    try {
      _bgShouldPlay = true;
      await _bgPlayer.setAsset('assets/sounds/bg_music.m4a');
      await _bgPlayer.setLoopMode(just_audio.LoopMode.all);
      await _bgPlayer.setVolume(_bgVolume);
      await _bgPlayer.play();
      debugPrint('🎵 Background music started (loop mode)');
    } catch (e) {
      _bgShouldPlay = false;
      debugPrint('🔇 BG music error: $e');
    }
  }

  /// Background musiqani to'xtatish
  Future<void> stopBgMusic() async {
    _bgShouldPlay = false;
    try {
      await _bgPlayer.stop();
      debugPrint('🎵 Background music stopped');
    } catch (e) {
      debugPrint('🔇 BG music stop error: $e');
    }
  }

  /// Background musiqa holati
  bool get isBgMusicPlaying => _bgShouldPlay;

  // ═══════════════════════════════════════
  // VOLUME SOZLAMALARI
  // ═══════════════════════════════════════

  /// BG musiqa ovoz balandligini o'zgartirish (0.0 — 1.0)
  Future<void> setBgVolume(double volume) async {
    _bgVolume = volume.clamp(0.0, 1.0);
    await _bgPlayer.setVolume(_bgVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_bgVolumeKey, _bgVolume);
  }

  /// SFX ovoz balandligini o'zgartirish (0.0 — 1.0)
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_sfxVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sfxVolumeKey, _sfxVolume);
  }

  // ═══════════════════════════════════════
  // SFX (audioplayers — SoundPool)
  // ═══════════════════════════════════════

  /// Umumiy ovoz chalish metodi
  Future<void> _play(String assetName) async {
    try {
      await _sfxPlayer.play(AssetSource('sounds/$assetName'));
    } catch (e) {
      debugPrint('🔇 Sound play error ($assetName): $e');
    }
  }

  /// Tugma bosilganda yoki rang tanlanganda
  Future<void> playPop() => _play('pop.wav');

  /// Rang to'ldirilganda
  Future<void> playFill() => _play('fill.wav');

  /// Ortga qaytish qilinganda
  Future<void> playUndo() => _play('undo.wav');

  /// Rasm to'liq bo'yalib bitganda (Celebration)
  Future<void> playSuccess() => _play('success.wav');

  /// Karta surilganda (yumshoq ovoz)
  Future<void> playSwipe() => _play('undo.wav');

  /// Intro ovozni oldindan yuklash (darhol play bo'lishi uchun)
  Future<void> preloadIntro() async {
    try {
      stopIntro();
      _introPlayer = just_audio.AudioPlayer(
        handleInterruptions: false,
        handleAudioSessionActivation: false,
        androidApplyAudioAttributes: false,
      );
      await _introPlayer!.setAsset('assets/sounds/intro_fanfare.mp3');
      await _introPlayer!.setVolume(_sfxVolume);
      debugPrint('🎵 Intro preloaded!');
    } catch (e) {
      debugPrint('🔇 Intro preload error: $e');
    }
  }

  /// Landing page kirish fanfare ovozi (preload qilingan bo'lsa darhol chalinadi)
  Future<void> playIntro() async {
    try {
      if (_introPlayer == null) {
        await preloadIntro();
      }
      await _introPlayer?.play();
      // Tugagandan keyin dispose
      _introPlayer?.playerStateStream.listen((state) {
        if (state.processingState == just_audio.ProcessingState.completed) {
          _introPlayer?.dispose();
          _introPlayer = null;
        }
      });
    } catch (e) {
      debugPrint('🔇 Intro sound error: $e');
    }
  }

  /// Intro ovozni darhol to'xtatish (sahifadan chiqganda)
  void stopIntro() {
    final player = _introPlayer;
    _introPlayer = null;
    if (player != null) {
      // Darhol ovozni 0 ga tushir va pause — kutmasdan
      player.setVolume(0);
      player.pause();
      // Keyin background'da tozala
      Future.microtask(() async {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
      });
    }
  }

  void dispose() {
    _bgShouldPlay = false;
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
    _isInit = false;
  }
}
