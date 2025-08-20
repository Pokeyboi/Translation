import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/audio_clip.dart';
import 'audio_store.dart';
import 'audio_repository.dart';

enum PlaybackState { stopped, playing, paused, loading, error }

enum ABLoopState { disabled, settingA, settingB, looping }

class PlaybackService {
  static PlaybackService? _instance;
  static PlaybackService get instance => _instance ??= PlaybackService._();
  PlaybackService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioStore _audioStore = AudioStore.instance;
  final AudioRepository _audioRepo = AudioRepository.instance;

  // Controllers
  final StreamController<PlaybackState> _stateController = StreamController.broadcast();
  final StreamController<Duration> _positionController = StreamController.broadcast();
  final StreamController<Duration> _durationController = StreamController.broadcast();
  final StreamController<double> _speedController = StreamController.broadcast();
  final StreamController<ABLoopState> _abLoopController = StreamController.broadcast();

  // State
  PlaybackState _currentState = PlaybackState.stopped;
  double _currentSpeed = 1.0;
  ABLoopState _abLoopState = ABLoopState.disabled;
  Duration? _loopPointA;
  Duration? _loopPointB;
  Timer? _abLoopTimer;
  String? _currentClipId;

  // Streams
  Stream<PlaybackState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<ABLoopState> get abLoopStream => _abLoopController.stream;

  // Getters
  PlaybackState get currentState => _currentState;
  double get currentSpeed => _currentSpeed;
  ABLoopState get abLoopState => _abLoopState;
  Duration? get loopPointA => _loopPointA;
  Duration? get loopPointB => _loopPointB;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;

  Future<void> initialize() async {
    try {
      // Initialize audio session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      // Initialize TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set up audio player listeners
      _audioPlayer.playerStateStream.listen((state) {
        if (state.playing) {
          _updateState(PlaybackState.playing);
        } else if (state.processingState == ProcessingState.completed) {
          _updateState(PlaybackState.stopped);
        } else {
          _updateState(PlaybackState.paused);
        }
      });

      _audioPlayer.positionStream.listen((position) {
        _positionController.add(position);
        _checkABLoop(position);
      });

      _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          _durationController.add(duration);
        }
      });

      _audioPlayer.speedStream.listen((speed) {
        _currentSpeed = speed;
        _speedController.add(speed);
      });

    } catch (e) {
      _updateState(PlaybackState.error);
      throw PlaybackException('Failed to initialize playback service: $e');
    }
  }

  /// Play audio clip by ID
  Future<void> playClip(String clipId) async {
    try {
      _updateState(PlaybackState.loading);
      _currentClipId = clipId;

      final clip = await _audioRepo.getClipById(clipId);
      if (clip == null) {
        throw PlaybackException('Audio clip not found');
      }

      String localPath;
      if (clip.storageUrl.startsWith('file:')) {
        localPath = clip.storageUrl.substring(5); // Remove 'file:' prefix
      } else {
        localPath = await _audioStore.fetch(clip.storageUrl);
      }

      if (!await _audioStore.existsLocal(localPath)) {
        throw PlaybackException('Audio file not found locally');
      }

      await _audioPlayer.setFilePath(localPath);
      await _audioPlayer.setSpeed(_currentSpeed);
      await _audioPlayer.play();

    } catch (e) {
      _updateState(PlaybackState.error);
      throw PlaybackException('Failed to play clip: $e');
    }
  }

  /// Play audio from URL or file path
  Future<void> playFromPath(String audioPath) async {
    try {
      _updateState(PlaybackState.loading);
      _currentClipId = null;

      if (audioPath.startsWith('http')) {
        await _audioPlayer.setUrl(audioPath);
      } else {
        await _audioPlayer.setFilePath(audioPath);
      }

      await _audioPlayer.setSpeed(_currentSpeed);
      await _audioPlayer.play();

    } catch (e) {
      _updateState(PlaybackState.error);
      throw PlaybackException('Failed to play audio: $e');
    }
  }

  /// Play text using TTS (English only)
  Future<void> playTTS(String text) async {
    try {
      _updateState(PlaybackState.loading);
      _currentClipId = null;
      
      await _flutterTts.speak(text);
      _updateState(PlaybackState.playing);

    } catch (e) {
      _updateState(PlaybackState.error);
      throw PlaybackException('Failed to play TTS: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
    await _flutterTts.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  /// Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _flutterTts.stop();
    _clearABLoop();
    _currentClipId = null;
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    await _audioPlayer.setSpeed(speed);
    _speedController.add(speed);
  }

  /// Toggle between 1.0x and 0.75x speed
  Future<void> toggleSpeed() async {
    final newSpeed = _currentSpeed == 1.0 ? 0.75 : 1.0;
    await setSpeed(newSpeed);
  }

  /// Set A-B loop points
  void setLoopPoint(String point) {
    final currentPosition = _audioPlayer.position;
    
    if (point == 'A') {
      _loopPointA = currentPosition;
      _abLoopState = ABLoopState.settingB;
      _abLoopController.add(_abLoopState);
    } else if (point == 'B') {
      _loopPointB = currentPosition;
      if (_loopPointA != null && _loopPointB!.inMilliseconds > _loopPointA!.inMilliseconds) {
        _abLoopState = ABLoopState.looping;
        _startABLoop();
      } else {
        clearABLoop();
      }
      _abLoopController.add(_abLoopState);
    }
  }

  /// Start A-B looping
  void _startABLoop() {
    _abLoopTimer?.cancel();
    _abLoopTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final position = _audioPlayer.position;
      if (_loopPointB != null && position.inMilliseconds >= _loopPointB!.inMilliseconds) {
        _audioPlayer.seek(_loopPointA ?? Duration.zero);
      }
    });
  }

  /// Clear A-B loop
  void clearABLoop() {
    _clearABLoop();
  }

  void _clearABLoop() {
    _abLoopTimer?.cancel();
    _abLoopTimer = null;
    _loopPointA = null;
    _loopPointB = null;
    _abLoopState = ABLoopState.disabled;
    _abLoopController.add(_abLoopState);
  }

  /// Check if current position is in A-B loop range
  void _checkABLoop(Duration position) {
    if (_abLoopState == ABLoopState.looping &&
        _loopPointB != null &&
        position.inMilliseconds >= _loopPointB!.inMilliseconds) {
      _audioPlayer.seek(_loopPointA ?? Duration.zero);
    }
  }

  /// Update playback state
  void _updateState(PlaybackState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Format duration for display
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Dispose resources
  void dispose() {
    _abLoopTimer?.cancel();
    _audioPlayer.dispose();
    _flutterTts.stop();
    _stateController.close();
    _positionController.close();
    _durationController.close();
    _speedController.close();
    _abLoopController.close();
  }
}

class PlaybackException implements Exception {
  final String message;
  PlaybackException(this.message);
  
  @override
  String toString() => 'PlaybackException: $message';
}