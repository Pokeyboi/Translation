import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../models/audio_clip.dart';
import 'audio_store.dart';
import 'audio_repository.dart';

enum RecorderState { idle, recording, paused, stopped }

class RecorderService {
  static RecorderService? _instance;
  static RecorderService get instance => _instance ??= RecorderService._();
  RecorderService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioStore _audioStore = AudioStore.instance;
  final AudioRepository _audioRepo = AudioRepository.instance;

  // Controllers
  final StreamController<RecorderState> _stateController = StreamController.broadcast();
  final StreamController<Duration> _durationController = StreamController.broadcast();
  final StreamController<double> _amplitudeController = StreamController.broadcast();

  // State
  RecorderState _currentState = RecorderState.idle;
  String? _currentRecordingPath;
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  DateTime? _recordingStartTime;

  // Streams
  Stream<RecorderState> get stateStream => _stateController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  // Getters
  RecorderState get currentState => _currentState;
  Duration get recordingDuration => _recordingStartTime != null
      ? DateTime.now().difference(_recordingStartTime!)
      : Duration.zero;

  /// Initialize recorder and check permissions
  Future<bool> initialize() async {
    try {
      // Check and request microphone permission
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        return false;
      }

      // Check if recording is available
      final isAvailable = await _recorder.hasPermission();
      return isAvailable;

    } catch (e) {
      print('Error initializing recorder: $e');
      return false;
    }
  }

  /// Check and request microphone permission
  Future<bool> _checkMicrophonePermission() async {
    try {
      PermissionStatus status = await Permission.microphone.status;
      
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      return status.isGranted;
    } catch (e) {
      print('Error checking microphone permission: $e');
      return false;
    }
  }

  /// Start recording
  Future<String?> startRecording({
    required String entryId,
    required String languageCode,
    String? variantLabel,
  }) async {
    try {
      if (_currentState == RecorderState.recording) {
        await stopRecording();
      }

      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        throw RecorderException('Microphone permission not granted');
      }

      // Generate filename
      final entrySlug = entryId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filename = _audioStore.generateFilename(
        languageCode: languageCode,
        entrySlug: entrySlug,
        speakerRole: 'temp', // Temporary, will be updated when saved
      );

      // Get temporary recording path
      _currentRecordingPath = await _getTempRecordingPath(filename);

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 256000,
        numChannels: 1, // Mono
      );

      // Start recording
      await _recorder.start(config, path: _currentRecordingPath!);
      
      _updateState(RecorderState.recording);
      _recordingStartTime = DateTime.now();
      _startTimers();

      return _currentRecordingPath;

    } catch (e) {
      _updateState(RecorderState.idle);
      throw RecorderException('Failed to start recording: $e');
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    try {
      if (_currentState != RecorderState.recording) return;

      await _recorder.pause();
      _updateState(RecorderState.paused);
      _stopTimers();

    } catch (e) {
      throw RecorderException('Failed to pause recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    try {
      if (_currentState != RecorderState.paused) return;

      await _recorder.resume();
      _updateState(RecorderState.recording);
      _startTimers();

    } catch (e) {
      throw RecorderException('Failed to resume recording: $e');
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    try {
      if (_currentState == RecorderState.idle) return null;

      final recordingPath = await _recorder.stop();
      _updateState(RecorderState.stopped);
      _stopTimers();

      return recordingPath ?? _currentRecordingPath;

    } catch (e) {
      _updateState(RecorderState.idle);
      throw RecorderException('Failed to stop recording: $e');
    }
  }

  /// Cancel recording and delete file
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _cleanup();

    } catch (e) {
      _cleanup();
      throw RecorderException('Failed to cancel recording: $e');
    }
  }

  /// Save recording as audio clip
  Future<AudioClip> saveRecording({
    required String entryId,
    required SpeakerRole speakerRole,
    required String userId,
    required String languageCode,
    String? studentId,
    String? classId,
    String? variantLabel,
    String? note,
    bool consentPublic = false,
  }) async {
    try {
      if (_currentRecordingPath == null || _currentState != RecorderState.stopped) {
        throw RecorderException('No recording to save');
      }

      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        throw RecorderException('Recording file not found');
      }

      // Read audio data
      final audioData = await file.readAsBytes();
      
      // Generate waveform peaks
      final waveformPeaks = _audioStore.generateWaveformPeaks(audioData);

      // Get file size and duration
      final fileSize = await file.length();
      final duration = recordingDuration;

      // Generate final filename
      final entrySlug = entryId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final finalFilename = _audioStore.generateFilename(
        languageCode: languageCode,
        entrySlug: entrySlug,
        speakerRole: speakerRole.name,
      );

      // Save to permanent location
      final permanentPath = await _audioStore.saveLocal(audioData, finalFilename);

      // Create audio clip
      final clip = AudioClip(
        entryId: entryId,
        speakerRole: speakerRole,
        userId: userId,
        studentId: studentId,
        classId: classId,
        languageCode: languageCode,
        variantLabel: variantLabel,
        note: note,
        durationMs: duration.inMilliseconds,
        consentPublic: consentPublic,
        storageUrl: 'file:$permanentPath',
        waveformPeaks: waveformPeaks,
      );

      // Save to database
      await _audioRepo.saveClip(clip);

      // Cleanup temporary file
      if (await file.exists()) {
        await file.delete();
      }
      _cleanup();

      return clip;

    } catch (e) {
      throw RecorderException('Failed to save recording: $e');
    }
  }

  /// Get recording amplitude (for level meter)
  Future<double> getAmplitude() async {
    try {
      if (_currentState != RecorderState.recording) return 0.0;

      final amplitude = await _recorder.getAmplitude();
      return amplitude.current;

    } catch (e) {
      return 0.0;
    }
  }

  /// Start monitoring timers
  void _startTimers() {
    _stopTimers();

    // Duration timer
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _durationController.add(recordingDuration);
    });

    // Amplitude timer for level meter
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      final amplitude = await getAmplitude();
      _amplitudeController.add(amplitude);
    });
  }

  /// Stop monitoring timers
  void _stopTimers() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _durationTimer = null;
    _amplitudeTimer = null;
  }

  /// Update recorder state
  void _updateState(RecorderState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Get temporary recording path
  Future<String> _getTempRecordingPath(String filename) async {
    final directory = await _audioStore.saveLocal(
      Uint8List(0), 
      'temp_$filename',
    );
    return directory;
  }

  /// Cleanup resources
  void _cleanup() {
    _updateState(RecorderState.idle);
    _stopTimers();
    _currentRecordingPath = null;
    _recordingStartTime = null;
  }

  /// Check if recording is supported
  Future<bool> isRecordingSupported() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  /// Get recording permission status
  Future<PermissionStatus> getPermissionStatus() async {
    return await Permission.microphone.status;
  }

  /// Show permission rationale
  String getPermissionRationale() {
    return 'Microphone access is needed to record pronunciation audio. '
           'This helps teachers and parents provide better language learning support.';
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _stopTimers();
    _stateController.close();
    _durationController.close();
    _amplitudeController.close();
  }
}

class RecorderException implements Exception {
  final String message;
  RecorderException(this.message);
  
  @override
  String toString() => 'RecorderException: $message';
}