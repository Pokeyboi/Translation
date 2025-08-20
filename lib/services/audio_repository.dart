import '../models/audio_clip.dart';
import 'database_service.dart';

class AudioRepository {
  static AudioRepository? _instance;
  static AudioRepository get instance => _instance ??= AudioRepository._();
  AudioRepository._();

  /// Save audio clip to database
  Future<void> saveClip(AudioClip clip) async {
    await DatabaseService.insert('audio_clips', clip.toJson());
  }

  /// Get all clips for a dictionary entry
  Future<List<AudioClip>> getClipsForEntry(String entryId) async {
    final results = await DatabaseService.query(
      'audio_clips',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'created_at DESC',
    );

    return results.map((json) => AudioClip.fromJson(json)).toList();
  }

  /// Get reference clip for an entry
  Future<AudioClip?> getReferenceClip(String entryId, String languageCode) async {
    final results = await DatabaseService.query(
      'audio_clips',
      where: 'entry_id = ? AND language_code = ? AND is_reference = 1',
      whereArgs: [entryId, languageCode],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return AudioClip.fromJson(results.first);
  }

  /// Set clip as reference (ensures only one reference per entry/language)
  Future<void> setAsReference(String clipId, String entryId, String languageCode) async {
    // First, remove reference flag from other clips
    await DatabaseService.update(
      'audio_clips',
      {'is_reference': 0},
      'entry_id = ? AND language_code = ? AND id != ?',
      [entryId, languageCode, clipId],
    );

    // Set this clip as reference
    await DatabaseService.update(
      'audio_clips',
      {'is_reference': 1},
      'id = ?',
      [clipId],
    );
  }

  /// Get clips by speaker role
  Future<List<AudioClip>> getClipsBySpeaker(String entryId, SpeakerRole role) async {
    final results = await DatabaseService.query(
      'audio_clips',
      where: 'entry_id = ? AND speaker_role = ?',
      whereArgs: [entryId, role.name],
      orderBy: 'created_at DESC',
    );

    return results.map((json) => AudioClip.fromJson(json)).toList();
  }

  /// Get clips for teacher review (parent recordings)
  Future<List<AudioClip>> getPendingReviewClips({
    String? classId,
    String? languageCode,
  }) async {
    String where = 'speaker_role = ?';
    List<dynamic> whereArgs = ['parent'];

    if (classId != null) {
      where += ' AND class_id = ?';
      whereArgs.add(classId);
    }

    if (languageCode != null) {
      where += ' AND language_code = ?';
      whereArgs.add(languageCode);
    }

    final results = await DatabaseService.query(
      'audio_clips',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return results.map((json) => AudioClip.fromJson(json)).toList();
  }

  /// Update clip metadata
  Future<void> updateClip(AudioClip clip) async {
    await DatabaseService.update(
      'audio_clips',
      clip.toJson(),
      'id = ?',
      [clip.id],
    );
  }

  /// Delete clip
  Future<void> deleteClip(String clipId) async {
    await DatabaseService.delete(
      'audio_clips',
      'id = ?',
      [clipId],
    );
  }

  /// Get clips by user
  Future<List<AudioClip>> getClipsByUser(String userId) async {
    final results = await DatabaseService.query(
      'audio_clips',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return results.map((json) => AudioClip.fromJson(json)).toList();
  }

  /// Get clips for offline sync (unuploaded clips)
  Future<List<AudioClip>> getPendingUploadClips() async {
    final results = await DatabaseService.query(
      'audio_clips',
      where: 'storage_url LIKE ?',
      whereArgs: ['file:%'], // Local file paths start with 'file:'
      orderBy: 'created_at ASC',
    );

    return results.map((json) => AudioClip.fromJson(json)).toList();
  }

  /// Mark clip as uploaded
  Future<void> markAsUploaded(String clipId, String remoteUrl) async {
    await DatabaseService.update(
      'audio_clips',
      {'storage_url': remoteUrl},
      'id = ?',
      [clipId],
    );
  }

  /// Get clips by language and variant
  Future<List<AudioClip>> getClipsByLanguage(
    String languageCode, {
    String? variantLabel,
  }) async {
    String where = 'language_code = ?';
    List<dynamic> whereArgs = [languageCode];

    if (variantLabel != null) {
      where += ' AND variant_label = ?';
      whereArgs.add(variantLabel);
    }

    final results = await DatabaseService.query(
      'audio_clips',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return results.map((json) => AudioClip.fromJson(json)).toList();
  }

  /// Search clips by note content
  Future<List<AudioClip>> searchClips(String query) async {
    final results = await DatabaseService.query(
      'audio_clips',
      where: 'note LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );

    return results.map((json) => AudioClip.fromJson(json)).toList();
  }

  /// Get clip by ID
  Future<AudioClip?> getClipById(String clipId) async {
    final results = await DatabaseService.query(
      'audio_clips',
      where: 'id = ?',
      whereArgs: [clipId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return AudioClip.fromJson(results.first);
  }

  /// Initialize database tables
  Future<void> initializeTables() async {
    final db = await DatabaseService.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audio_clips (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        speaker_role TEXT NOT NULL,
        user_id TEXT NOT NULL,
        student_id TEXT,
        class_id TEXT,
        language_code TEXT NOT NULL,
        variant_label TEXT,
        note TEXT,
        duration_ms INTEGER NOT NULL,
        consent_public INTEGER DEFAULT 0,
        is_reference INTEGER DEFAULT 0,
        storage_url TEXT NOT NULL,
        waveform_peaks TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (entry_id) REFERENCES dictionary_entries (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_audio_clips_entry_id 
      ON audio_clips (entry_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_audio_clips_language_reference 
      ON audio_clips (language_code, is_reference)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_audio_clips_speaker_role 
      ON audio_clips (speaker_role)
    ''');
  }
}