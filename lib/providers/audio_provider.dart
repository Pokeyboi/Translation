import 'package:flutter/foundation.dart';
import '../models/audio_clip.dart';
import '../services/audio_repository.dart';
import '../services/playback_service.dart';
import '../services/recorder_service.dart';
import '../services/audio_store.dart';

class AudioProvider extends ChangeNotifier {
  final AudioRepository _audioRepo = AudioRepository.instance;
  final PlaybackService _playback = PlaybackService.instance;
  final RecorderService _recorder = RecorderService.instance;
  final AudioStore _audioStore = AudioStore.instance;

  // State
  List<AudioClip> _clipsForEntry = [];
  List<AudioClip> _pendingReviewClips = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AudioClip> get clipsForEntry => List.unmodifiable(_clipsForEntry);
  List<AudioClip> get pendingReviewClips => List.unmodifiable(_pendingReviewClips);
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize audio services and database
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      await _audioRepo.initializeTables();
      await _playback.initialize();
      await _recorder.initialize();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize audio services: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load audio clips for a dictionary entry
  Future<void> loadClipsForEntry(String entryId) async {
    _setLoading(true);
    _clearError();

    try {
      _clipsForEntry = await _audioRepo.getClipsForEntry(entryId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load audio clips: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get reference clip for an entry and language
  Future<AudioClip?> getReferenceClip(String entryId, String languageCode) async {
    try {
      return await _audioRepo.getReferenceClip(entryId, languageCode);
    } catch (e) {
      _setError('Failed to get reference clip: $e');
      return null;
    }
  }

  /// Set a clip as reference
  Future<void> setAsReference(AudioClip clip) async {
    _setLoading(true);
    _clearError();

    try {
      await _audioRepo.setAsReference(clip.id, clip.entryId, clip.languageCode);
      
      // Update local state
      _clipsForEntry = _clipsForEntry.map((c) {
        if (c.entryId == clip.entryId && c.languageCode == clip.languageCode) {
          return c.copyWith(isReference: c.id == clip.id);
        }
        return c;
      }).toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to set reference clip: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save a new audio clip
  Future<AudioClip?> saveClip(AudioClip clip) async {
    _setLoading(true);
    _clearError();

    try {
      await _audioRepo.saveClip(clip);
      
      // Add to local state if it matches current entry
      if (_clipsForEntry.any((c) => c.entryId == clip.entryId)) {
        _clipsForEntry.insert(0, clip);
        notifyListeners();
      }

      return clip;
    } catch (e) {
      _setError('Failed to save audio clip: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing audio clip
  Future<void> updateClip(AudioClip clip) async {
    _setLoading(true);
    _clearError();

    try {
      await _audioRepo.updateClip(clip);
      
      // Update local state
      final index = _clipsForEntry.indexWhere((c) => c.id == clip.id);
      if (index != -1) {
        _clipsForEntry[index] = clip;
        notifyListeners();
      }
      
      final reviewIndex = _pendingReviewClips.indexWhere((c) => c.id == clip.id);
      if (reviewIndex != -1) {
        _pendingReviewClips[reviewIndex] = clip;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update audio clip: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an audio clip
  Future<void> deleteClip(String clipId) async {
    _setLoading(true);
    _clearError();

    try {
      // Get clip details before deletion for cleanup
      final clip = await _audioRepo.getClipById(clipId);
      
      await _audioRepo.deleteClip(clipId);
      
      // Clean up local file if it exists
      if (clip != null && clip.storageUrl.startsWith('file:')) {
        final localPath = clip.storageUrl.substring(5);
        if (await _audioStore.existsLocal(localPath)) {
          // Note: In production, you might want to be more careful about deleting files
          // that might be referenced by other clips
        }
      }
      
      // Remove from local state
      _clipsForEntry.removeWhere((c) => c.id == clipId);
      _pendingReviewClips.removeWhere((c) => c.id == clipId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete audio clip: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load clips pending teacher review
  Future<void> loadPendingReviewClips({String? classId, String? languageCode}) async {
    _setLoading(true);
    _clearError();

    try {
      _pendingReviewClips = await _audioRepo.getPendingReviewClips(
        classId: classId,
        languageCode: languageCode,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load review clips: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get clips by speaker role for an entry
  Future<List<AudioClip>> getClipsBySpeaker(String entryId, SpeakerRole role) async {
    try {
      return await _audioRepo.getClipsBySpeaker(entryId, role);
    } catch (e) {
      _setError('Failed to get clips by speaker: $e');
      return [];
    }
  }

  /// Play an audio clip
  Future<void> playClip(AudioClip clip) async {
    _clearError();

    try {
      await _playback.playClip(clip.id);
    } catch (e) {
      _setError('Failed to play clip: $e');
    }
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    try {
      await _playback.stop();
    } catch (e) {
      _setError('Failed to stop playback: $e');
    }
  }

  /// Get clips for offline sync
  Future<List<AudioClip>> getPendingUploadClips() async {
    try {
      return await _audioRepo.getPendingUploadClips();
    } catch (e) {
      _setError('Failed to get pending uploads: $e');
      return [];
    }
  }

  /// Mark clip as uploaded
  Future<void> markAsUploaded(String clipId, String remoteUrl) async {
    try {
      await _audioRepo.markAsUploaded(clipId, remoteUrl);
      
      // Update local state
      _updateClipInLists(clipId, (clip) => clip.copyWith(storageUrl: remoteUrl));
    } catch (e) {
      _setError('Failed to mark as uploaded: $e');
    }
  }

  /// Search clips
  Future<List<AudioClip>> searchClips(String query) async {
    try {
      return await _audioRepo.searchClips(query);
    } catch (e) {
      _setError('Failed to search clips: $e');
      return [];
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    try {
      return await _audioStore.getCacheSize();
    } catch (e) {
      _setError('Failed to get cache size: $e');
      return 0;
    }
  }

  /// Clear audio cache
  Future<void> clearCache() async {
    _setLoading(true);
    _clearError();

    try {
      await _audioStore.clearCache();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear cache: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Format cache size for display
  String formatCacheSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Helper method to update a clip in all local lists
  void _updateClipInLists(String clipId, AudioClip Function(AudioClip) updater) {
    // Update in clipsForEntry
    final entryIndex = _clipsForEntry.indexWhere((c) => c.id == clipId);
    if (entryIndex != -1) {
      _clipsForEntry[entryIndex] = updater(_clipsForEntry[entryIndex]);
    }

    // Update in pendingReviewClips
    final reviewIndex = _pendingReviewClips.indexWhere((c) => c.id == clipId);
    if (reviewIndex != -1) {
      _pendingReviewClips[reviewIndex] = updater(_pendingReviewClips[reviewIndex]);
    }

    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _error = null;
    // Note: Don't notify listeners here to avoid unnecessary rebuilds
  }

  /// Reset all state
  void reset() {
    _clipsForEntry.clear();
    _pendingReviewClips.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}