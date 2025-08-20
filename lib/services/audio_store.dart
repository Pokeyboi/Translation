import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AudioStore {
  static AudioStore? _instance;
  static AudioStore get instance => _instance ??= AudioStore._();
  AudioStore._();

  static const int _cacheRetentionDays = 30;
  static const String _audioFolder = 'audio_cache';

  /// Save WAV data locally and return the local path
  Future<String> saveLocal(Uint8List wavData, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory(path.join(directory.path, _audioFolder));
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final filePath = path.join(audioDir.path, filename);
      final file = File(filePath);
      await file.writeAsBytes(wavData);

      return filePath;
    } catch (e) {
      throw AudioStoreException('Failed to save audio locally: $e');
    }
  }

  /// Generate a consistent filename for audio clips
  String generateFilename({
    required String languageCode,
    required String entrySlug,
    required String speakerRole,
    String? timestamp,
  }) {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch.toString();
    return '${languageCode}_${entrySlug}__${speakerRole}__$ts.wav';
  }

  /// Upload local file to remote storage (mock implementation)
  Future<String> upload(String localPath) async {
    try {
      // In a real implementation, this would upload to your storage service
      // For now, we'll simulate by returning a mock URL
      final fileName = path.basename(localPath);
      final mockUrl = 'https://storage.example.com/audio/$fileName';
      
      // Simulate upload delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return mockUrl;
    } catch (e) {
      throw AudioStoreException('Failed to upload audio: $e');
    }
  }

  /// Fetch audio from remote URL and cache locally
  Future<String> fetch(String storageUrl) async {
    try {
      // Check if already cached
      final fileName = path.basename(Uri.parse(storageUrl).path);
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory(path.join(directory.path, _audioFolder));
      final cachedFile = File(path.join(audioDir.path, fileName));

      if (await cachedFile.exists()) {
        // Update access time
        await cachedFile.setLastAccessed(DateTime.now());
        return cachedFile.path;
      }

      // Download from remote
      final response = await http.get(Uri.parse(storageUrl));
      if (response.statusCode != 200) {
        throw AudioStoreException('Failed to download audio: HTTP ${response.statusCode}');
      }

      // Create cache directory if needed
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Save to cache
      await cachedFile.writeAsBytes(response.bodyBytes);
      return cachedFile.path;

    } catch (e) {
      throw AudioStoreException('Failed to fetch audio: $e');
    }
  }

  /// Check if file exists locally
  Future<bool> existsLocal(String localPath) async {
    return File(localPath).exists();
  }

  /// Get file size
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return 0;
    return file.length();
  }

  /// Clean up old cached files
  Future<void> cleanupCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory(path.join(directory.path, _audioFolder));

      if (!await audioDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(
        const Duration(days: _cacheRetentionDays),
      );

      await for (final entity in audioDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.accessed.isBefore(cutoffDate)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Log error but don't throw
      print('Error cleaning up audio cache: $e');
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory(path.join(directory.path, _audioFolder));

      if (!await audioDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in audioDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all cached audio files
  Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory(path.join(directory.path, _audioFolder));

      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }
    } catch (e) {
      throw AudioStoreException('Failed to clear cache: $e');
    }
  }

  /// Generate waveform peaks from audio data (simplified implementation)
  List<double> generateWaveformPeaks(Uint8List audioData, {int peakCount = 100}) {
    if (audioData.length < 44) return []; // Invalid WAV file

    // Skip WAV header (44 bytes)
    final audioSamples = audioData.sublist(44);
    final sampleSize = 2; // 16-bit samples
    final samplesPerPeak = (audioSamples.length ~/ sampleSize) ~/ peakCount;
    
    if (samplesPerPeak <= 0) return [];

    final peaks = <double>[];
    
    for (int i = 0; i < peakCount; i++) {
      double maxAmplitude = 0.0;
      final startIndex = i * samplesPerPeak * sampleSize;
      final endIndex = min(startIndex + samplesPerPeak * sampleSize, audioSamples.length - 1);
      
      for (int j = startIndex; j < endIndex; j += sampleSize) {
        if (j + 1 < audioSamples.length) {
          // Read 16-bit sample (little endian)
          final sample = (audioSamples[j + 1] << 8) | audioSamples[j];
          final amplitude = (sample - 32768).abs() / 32768.0;
          maxAmplitude = max(maxAmplitude, amplitude);
        }
      }
      
      peaks.add(maxAmplitude);
    }
    
    return peaks;
  }
}

class AudioStoreException implements Exception {
  final String message;
  AudioStoreException(this.message);
  
  @override
  String toString() => 'AudioStoreException: $message';
}