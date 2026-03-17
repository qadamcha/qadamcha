import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Sound service for Jigsaw Puzzle with modern pop/drop SFX and persistent background music.
/// Uses separate AudioPlayers with AudioContext to prevent interference.
class JigsawSoundService with WidgetsBindingObserver {
  static final JigsawSoundService _instance = JigsawSoundService._internal();
  factory JigsawSoundService() => _instance;
  JigsawSoundService._internal() {
    WidgetsBinding.instance.addObserver(this);
    _configurePlayers();
  }

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer2 = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _bgMusicPlaying = false;
  bool _bgMusicStarted = false;

  bool get soundEnabled => _soundEnabled;

  /// Configure all players so SFX doesn't steal audio focus from BG music
  void _configurePlayers() {
    final sfxContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        audioFocus: AndroidAudioFocus.none,
        usageType: AndroidUsageType.game,
        contentType: AndroidContentType.sonification,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );

    _sfxPlayer.setAudioContext(sfxContext);
    _sfxPlayer2.setAudioContext(sfxContext);

    final bgContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        audioFocus: AndroidAudioFocus.gain,
        usageType: AndroidUsageType.game,
        contentType: AndroidContentType.music,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );

    _bgPlayer.setAudioContext(bgContext);
  }

  /// Handle app lifecycle — pause BG when backgrounded, resume when foregrounded
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _bgMusicStarted && _bgMusicPlaying && _soundEnabled) {
      _bgPlayer.resume();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_bgMusicPlaying) {
        _bgPlayer.pause();
      }
    }
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    if (_soundEnabled) {
      if (_bgMusicStarted) {
        _bgPlayer.resume();
      } else {
        startBackgroundMusic();
      }
    } else {
      _bgPlayer.pause();
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _sfxPlayer.dispose();
    await _sfxPlayer2.dispose();
    await _bgPlayer.dispose();
  }

  /// Start looping background music at low volume
  Future<void> startBackgroundMusic() async {
    if (_bgMusicPlaying) return;
    _bgMusicPlaying = true;
    _bgMusicStarted = true;
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.setVolume(0.12);
    await _bgPlayer.play(AssetSource('sounds/Funny-Kids-Toddler-Music-Song-For-Videos.m4a'));
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    _bgMusicPlaying = false;
    _bgMusicStarted = false;
    await _bgPlayer.stop();
  }

  // ──── MODERN SOUND EFFECTS ────

  /// Water drip sound for all button taps — uses real audio file
  Future<void> playTap() async {
    if (!_soundEnabled) return;
    await _sfxPlayer2.play(AssetSource('sounds/25879__acclivity__drip1.wav'));
  }

  /// Shimmer rising sound when picking up a piece
  Future<void> playPickup() async {
    if (!_soundEnabled) return;
    final wav = _generateRisingShimmer(volume: 0.55);
    await _sfxPlayer.play(BytesSource(wav));
  }

  /// Satisfying "bling" when piece snaps correctly
  Future<void> playSnap() async {
    if (!_soundEnabled) return;
    final wav = _generateSnapBling(volume: 0.55);
    await _sfxPlayer.play(BytesSource(wav));
  }

  /// Soft descending "boop" for wrong placement
  Future<void> playWrong() async {
    if (!_soundEnabled) return;
    final wav = _generateWrongBoop(volume: 0.4);
    await _sfxPlayer.play(BytesSource(wav));
  }

  /// Victory fanfare — rich ascending notes with harmonics
  Future<void> playVictory() async {
    if (!_soundEnabled) return;
    final wav = _generateVictoryFanfare(volume: 0.5);
    await _sfxPlayer.play(BytesSource(wav));
  }

  // ──── MODERN WAV GENERATORS ────

  static const int _sampleRate = 44100;

  /// Water drip sound for UI taps
  Uint8List _generatePopDrop({required double volume}) {
    const durationMs = 80;
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;

      // Water drip: steep frequency sweep 3500→600Hz
      final freq = 3500 * exp(-progress * 3.5) + 600;
      // Fast decay with a small resonant bounce
      final envelope = exp(-progress * 6.0) + 0.15 * exp(-progress * 2.0) * sin(pi * progress * 3);

      final val = ((sin(2 * pi * freq * t) * 0.75 +
                  sin(2 * pi * freq * 2.3 * t) * 0.25) *
              32767 *
              volume *
              envelope.clamp(0.0, 1.0))
          .round();
      samples[i] = val.clamp(-32768, 32767);
    }

    return _encodeWav(samples, _sampleRate);
  }

  /// Rising shimmer: frequency sweep upward with harmonics
  Uint8List _generateRisingShimmer({required double volume}) {
    const durationMs = 80;
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;

      // Frequency sweeps from 500Hz → 1600Hz (rising)
      final freq = 500 + (1100 * progress);
      // Bell-shaped envelope (quick attack, smooth decay)
      final envelope = sin(pi * progress) * exp(-progress * 2.0);

      final val = ((sin(2 * pi * freq * t) * 0.7 +
                  sin(2 * pi * freq * 2.0 * t) * 0.2 +
                  sin(2 * pi * freq * 3.0 * t) * 0.1) *
              32767 *
              volume *
              envelope)
          .round();
      samples[i] = val.clamp(-32768, 32767);
    }

    return _encodeWav(samples, _sampleRate);
  }

  /// Crystalline bell "ting" for correct snap
  Uint8List _generateSnapBling({required double volume}) {
    const durationMs = 200;
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;

      // Crystal bell: 1760Hz (A6) with rich harmonics
      const freq = 1760.0;
      // Quick attack, long resonant decay
      final envelope = (progress < 0.02)
          ? (progress / 0.02)
          : exp(-progress * 3.5);

      // Bell harmonics: fundamental + 2x + 3x + 5x for glass quality
      final val = ((sin(2 * pi * freq * t) * 0.45 +
                  sin(2 * pi * freq * 2.0 * t) * 0.25 +
                  sin(2 * pi * freq * 3.0 * t) * 0.18 +
                  sin(2 * pi * freq * 5.0 * t) * 0.12) *
              32767 *
              volume *
              envelope)
          .round();
      samples[i] = val.clamp(-32768, 32767);
    }

    return _encodeWav(samples, _sampleRate);
  }

  /// Dull bell for wrong placement — similar to snap but lower pitch
  Uint8List _generateWrongBoop({required double volume}) {
    const durationMs = 200;
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;

      // Lower dull bell: 440Hz (A4) — same shape as snap but lower
      const freq = 440.0;
      final envelope = (progress < 0.02)
          ? (progress / 0.02)
          : exp(-progress * 4.0);

      // Fewer harmonics for duller quality
      final val = ((sin(2 * pi * freq * t) * 0.6 +
                  sin(2 * pi * freq * 2.0 * t) * 0.25 +
                  sin(2 * pi * freq * 2.8 * t) * 0.15) *
              32767 *
              volume *
              envelope)
          .round();
      samples[i] = val.clamp(-32768, 32767);
    }

    return _encodeWav(samples, _sampleRate);
  }

  /// Victory fanfare: rich ascending melody with harmonics
  Uint8List _generateVictoryFanfare({required double volume}) {
    final notes = [523.0, 659.0, 784.0, 1047.0]; // C5→E5→G5→C6
    const noteDurationMs = 140;
    final samplesPerNote = (_sampleRate * noteDurationMs / 1000).round();
    final totalSamples = samplesPerNote * notes.length;
    final samples = Int16List(totalSamples);

    for (int n = 0; n < notes.length; n++) {
      final freq = notes[n];
      final offset = n * samplesPerNote;

      for (int i = 0; i < samplesPerNote; i++) {
        final t = i / _sampleRate;
        final progress = i / samplesPerNote;

        // Bell envelope
        double envelope;
        if (progress < 0.05) {
          envelope = progress / 0.05;
        } else {
          envelope = exp(-(progress - 0.05) * 3.0);
        }

        // Rich tone with harmonics
        final val = ((sin(2 * pi * freq * t) * 0.55 +
                    sin(2 * pi * freq * 2.0 * t) * 0.25 +
                    sin(2 * pi * freq * 3.0 * t) * 0.12 +
                    sin(2 * pi * freq * 4.0 * t) * 0.08) *
                32767 *
                volume *
                envelope)
            .round();
        samples[offset + i] = val.clamp(-32768, 32767);
      }
    }

    return _encodeWav(samples, _sampleRate);
  }

  /// Encode Int16 samples into a valid WAV file byte array.
  Uint8List _encodeWav(Int16List samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // (space)
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);

    // data chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
