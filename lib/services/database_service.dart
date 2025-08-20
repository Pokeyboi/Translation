import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/dictionary_entry.dart';
import '../models/message_model.dart';
import '../models/class_model.dart';
import '../models/audio_clip.dart';
import '../models/language_pack.dart';
import '../models/phrase_entry.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'translation_app.db';
  static const int _databaseVersion = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        phone_number TEXT,
        preferred_language TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Dictionary entries table
    await db.execute('''
      CREATE TABLE dictionary_entries (
        id TEXT PRIMARY KEY,
        language_code TEXT NOT NULL,
        language_name TEXT NOT NULL,
        dialect_label TEXT,
        english TEXT NOT NULL,
        translation TEXT NOT NULL,
        phonetic_helper TEXT,
        notes TEXT,
        category TEXT,
        tags TEXT,
        audio_native_url TEXT,
        audio_teacher_url TEXT,
        verified INTEGER DEFAULT 0,
        verified_by TEXT,
        source TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sense_id TEXT,
        part_of_speech TEXT,
        synonyms TEXT,
        examples TEXT
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        recipient_id TEXT NOT NULL,
        class_id TEXT,
        student_id TEXT,
        english_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        language_code TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        template_id TEXT,
        attachment_urls TEXT,
        audio_english_url TEXT,
        audio_translated_url TEXT,
        category TEXT,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sent_at TEXT,
        delivered_at TEXT,
        read_at TEXT,
        FOREIGN KEY (sender_id) REFERENCES users (id),
        FOREIGN KEY (recipient_id) REFERENCES users (id)
      )
    ''');

    // Classes table
    await db.execute('''
      CREATE TABLE classes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        teacher_id TEXT NOT NULL,
        description TEXT,
        grade TEXT,
        subject TEXT,
        student_ids TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES users (id)
      )
    ''');

    // Students table
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        class_id TEXT NOT NULL,
        parent_ids TEXT,
        grade TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes (id)
      )
    ''');

    // Audio clips table
    await db.execute('''
      CREATE TABLE audio_clips (
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
        FOREIGN KEY (entry_id) REFERENCES dictionary_entries (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Message attachments table
    await db.execute('''
      CREATE TABLE message_attachments (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        type TEXT NOT NULL,
        clip_id TEXT,
        url TEXT,
        display_label TEXT,
        file_size_bytes INTEGER,
        mime_type TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (message_id) REFERENCES messages (id),
        FOREIGN KEY (clip_id) REFERENCES audio_clips (id)
      )
    ''');

    // Language packs table
    await db.execute('''
      CREATE TABLE language_packs (
        id TEXT PRIMARY KEY,
        language_code TEXT NOT NULL,
        language_name TEXT NOT NULL,
        dialect_labels TEXT,
        version TEXT NOT NULL,
        entries_count INTEGER NOT NULL,
        audio_base_path TEXT NOT NULL,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        license TEXT NOT NULL,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        installed_at TEXT NOT NULL,
        allow_machine_translation INTEGER DEFAULT 0,
        mt_provider TEXT,
        tokenization_rules TEXT,
        join_rules TEXT,
        date_time_formats TEXT
      )
    ''');

    // Message templates table
    await db.execute('''
      CREATE TABLE message_templates (
        id TEXT PRIMARY KEY,
        english_text TEXT NOT NULL,
        category TEXT NOT NULL,
        tags TEXT,
        is_common INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Phrase entries table
    await db.execute('''
      CREATE TABLE phrase_entries (
        id TEXT PRIMARY KEY,
        language_code TEXT NOT NULL,
        language_name TEXT NOT NULL,
        dialect_label TEXT,
        phrase_key TEXT NOT NULL,
        english_text TEXT NOT NULL,
        translation_text TEXT NOT NULL,
        variables_json TEXT,
        category TEXT,
        tags TEXT,
        phonetic_helper TEXT,
        notes TEXT,
        audio_native_url TEXT,
        audio_teacher_url TEXT,
        verified INTEGER DEFAULT 0,
        verified_by TEXT,
        source TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_dictionary_entries_language ON dictionary_entries(language_code)');
    await db.execute('CREATE INDEX idx_dictionary_entries_english ON dictionary_entries(english)');
    await db.execute('CREATE INDEX idx_messages_sender ON messages(sender_id)');
    await db.execute('CREATE INDEX idx_messages_recipient ON messages(recipient_id)');
    await db.execute('CREATE INDEX idx_messages_status ON messages(status)');
    await db.execute('CREATE INDEX idx_audio_clips_entry ON audio_clips(entry_id)');
    await db.execute('CREATE INDEX idx_audio_clips_language_ref ON audio_clips(language_code, is_reference)');
    await db.execute('CREATE INDEX idx_audio_clips_speaker ON audio_clips(speaker_role)');
    await db.execute('CREATE INDEX idx_message_attachments_message ON message_attachments(message_id)');
    await db.execute('CREATE INDEX idx_phrase_entries_language ON phrase_entries(language_code)');
    await db.execute('CREATE INDEX idx_phrase_entries_english ON phrase_entries(english_text)');
    await db.execute('CREATE INDEX idx_phrase_entries_key ON phrase_entries(phrase_key)');
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to dictionary_entries
      await db.execute('ALTER TABLE dictionary_entries ADD COLUMN sense_id TEXT');
      await db.execute('ALTER TABLE dictionary_entries ADD COLUMN part_of_speech TEXT');
      await db.execute('ALTER TABLE dictionary_entries ADD COLUMN synonyms TEXT');
      await db.execute('ALTER TABLE dictionary_entries ADD COLUMN examples TEXT');

      // Add new columns to language_packs
      await db.execute('ALTER TABLE language_packs ADD COLUMN allow_machine_translation INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE language_packs ADD COLUMN mt_provider TEXT');
      await db.execute('ALTER TABLE language_packs ADD COLUMN tokenization_rules TEXT');
      await db.execute('ALTER TABLE language_packs ADD COLUMN join_rules TEXT');
      await db.execute('ALTER TABLE language_packs ADD COLUMN date_time_formats TEXT');

      // Create phrase_entries table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS phrase_entries (
          id TEXT PRIMARY KEY,
          language_code TEXT NOT NULL,
          language_name TEXT NOT NULL,
          dialect_label TEXT,
          phrase_key TEXT NOT NULL,
          english_text TEXT NOT NULL,
          translation_text TEXT NOT NULL,
          variables_json TEXT,
          category TEXT,
          tags TEXT,
          phonetic_helper TEXT,
          notes TEXT,
          audio_native_url TEXT,
          audio_teacher_url TEXT,
          verified INTEGER DEFAULT 0,
          verified_by TEXT,
          source TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create indexes for phrase_entries
      await db.execute('CREATE INDEX idx_phrase_entries_language ON phrase_entries(language_code)');
      await db.execute('CREATE INDEX idx_phrase_entries_english ON phrase_entries(english_text)');
      await db.execute('CREATE INDEX idx_phrase_entries_key ON phrase_entries(phrase_key)');
    }
  }

  // Generic CRUD operations
  static Future<List<Map<String, dynamic>>> query(String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  static Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  static Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  static Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // User-specific methods
  static Future<UserModel?> getUserById(String id) async {
    final results = await query('users', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final results = await query('users', where: 'email = ?', whereArgs: [email]);
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }

  static Future<String> saveUser(UserModel user) async {
    await insert('users', user.toJson());
    return user.id;
  }

  static Future<void> updateUser(UserModel user) async {
    await update('users', user.toJson(), 'id = ?', [user.id]);
  }

  // Dictionary-specific methods
  static Future<List<DictionaryEntry>> searchDictionary(String query, {String? languageCode, String? category, int? limit}) async {
    String whereClause = 'english LIKE ? OR translation LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];
    
    if (languageCode != null) {
      whereClause += ' AND language_code = ?';
      whereArgs.add(languageCode);
    }
    
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final results = await DatabaseService.query(
      'dictionary_entries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'english ASC',
      limit: limit,
    );

    return results.map((json) => DictionaryEntry.fromJson(json)).toList();
  }

  static Future<String> saveDictionaryEntry(DictionaryEntry entry) async {
    await insert('dictionary_entries', entry.toJson());
    return entry.id;
  }

  static Future<void> updateDictionaryEntry(DictionaryEntry entry) async {
    await update('dictionary_entries', entry.toJson(), 'id = ?', [entry.id]);
  }

  static Future<void> importDictionaryEntries(List<DictionaryEntry> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in entries) {
        batch.insert('dictionary_entries', entry.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<List<DictionaryEntry>> getDictionaryEntries({String? languageCode, String? category, int? limit}) async {
    String? whereClause;
    List<dynamic>? whereArgs;

    if (languageCode != null && category != null) {
      whereClause = 'language_code = ? AND category = ?';
      whereArgs = [languageCode, category];
    } else if (languageCode != null) {
      whereClause = 'language_code = ?';
      whereArgs = [languageCode];
    } else if (category != null) {
      whereClause = 'category = ?';
      whereArgs = [category];
    }

    final results = await query(
      'dictionary_entries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'english ASC',
      limit: limit,
    );

    return results.map((json) => DictionaryEntry.fromJson(json)).toList();
  }

  // Phrase-specific methods
  static Future<List<PhraseEntry>> searchPhrases(String query, {String? languageCode, String? category, int? limit}) async {
    String whereClause = 'english_text LIKE ? OR translation_text LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];
    
    if (languageCode != null) {
      whereClause += ' AND language_code = ?';
      whereArgs.add(languageCode);
    }
    
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final results = await DatabaseService.query(
      'phrase_entries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'english_text ASC',
      limit: limit,
    );

    return results.map((json) => PhraseEntry.fromJson(json)).toList();
  }

  static Future<List<PhraseEntry>> getAllPhrases(String languageCode) async {
    final results = await DatabaseService.query(
      'phrase_entries',
      where: 'language_code = ?',
      whereArgs: [languageCode],
      orderBy: 'english_text ASC',
    );

    return results.map((json) => PhraseEntry.fromJson(json)).toList();
  }

  static Future<String> savePhraseEntry(PhraseEntry entry) async {
    final jsonData = entry.toJson();
    // Convert variables to JSON string for storage
    if (jsonData['variables_json'] is List) {
      jsonData['variables_json'] = jsonEncode(jsonData['variables_json']);
    }
    await insert('phrase_entries', jsonData);
    return entry.id;
  }

  static Future<void> updatePhraseEntry(PhraseEntry entry) async {
    final jsonData = entry.toJson();
    // Convert variables to JSON string for storage
    if (jsonData['variables_json'] is List) {
      jsonData['variables_json'] = jsonEncode(jsonData['variables_json']);
    }
    await update('phrase_entries', jsonData, 'id = ?', [entry.id]);
  }

  static Future<List<PhraseEntry>> getPhraseEntries({String? languageCode, String? category, int? limit}) async {
    String? whereClause;
    List<dynamic>? whereArgs;

    if (languageCode != null && category != null) {
      whereClause = 'language_code = ? AND category = ?';
      whereArgs = [languageCode, category];
    } else if (languageCode != null) {
      whereClause = 'language_code = ?';
      whereArgs = [languageCode];
    } else if (category != null) {
      whereClause = 'category = ?';
      whereArgs = [category];
    }

    final results = await query(
      'phrase_entries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'english_text ASC',
      limit: limit,
    );

    return results.map((json) => PhraseEntry.fromJson(json)).toList();
  }

  static Future<void> deletePhraseEntry(String id) async {
    await delete('phrase_entries', 'id = ?', [id]);
  }

  // Language pack methods with enhanced functionality
  static Future<List<LanguagePack>> getLanguagePacks() async {
    final results = await query('language_packs', orderBy: 'language_name ASC');
    return results.map((json) => LanguagePack.fromJson(json)).toList();
  }

  static Future<void> saveLanguagePack(LanguagePack pack) async {
    final jsonData = pack.toJson();
    // Convert complex objects to JSON strings
    if (jsonData['tokenization_rules'] != null) {
      jsonData['tokenization_rules'] = jsonEncode(jsonData['tokenization_rules']);
    }
    if (jsonData['join_rules'] != null) {
      jsonData['join_rules'] = jsonEncode(jsonData['join_rules']);
    }
    if (jsonData['date_time_formats'] != null) {
      jsonData['date_time_formats'] = jsonEncode(jsonData['date_time_formats']);
    }
    
    await insert('language_packs', jsonData);
  }

  // Message-specific methods
  static Future<String> saveMessage(MessageModel message) async {
    await insert('messages', message.toJson());
    return message.id;
  }

  static Future<void> updateMessage(MessageModel message) async {
    await update('messages', message.toJson(), 'id = ?', [message.id]);
  }

  static Future<List<MessageModel>> getMessages({String? userId, String? classId, String? category}) async {
    String? whereClause;
    List<dynamic>? whereArgs;

    if (userId != null && classId != null) {
      whereClause = '(sender_id = ? OR recipient_id = ?) AND class_id = ?';
      whereArgs = [userId, userId, classId];
    } else if (userId != null) {
      whereClause = 'sender_id = ? OR recipient_id = ?';
      whereArgs = [userId, userId];
    } else if (classId != null) {
      whereClause = 'class_id = ?';
      whereArgs = [classId];
    }

    if (category != null) {
      if (whereClause != null) {
        whereClause += ' AND category = ?';
        whereArgs!.add(category);
      } else {
        whereClause = 'category = ?';
        whereArgs = [category];
      }
    }

    final results = await query(
      'messages',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return results.map((json) => MessageModel.fromJson(json)).toList();
  }

  // Instance methods for audio repository
  Future<List<Map<String, dynamic>>> queryData(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await query(table, 
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<void> insertOrUpdateData(String table, Map<String, dynamic> data) async {
    final id = data['id'];
    if (id != null) {
      final existing = await query(table, where: 'id = ?', whereArgs: [id]);
      if (existing.isNotEmpty) {
        await update(table, data, 'id = ?', [id]);
      } else {
        await insert(table, data);
      }
    } else {
      await insert(table, data);
    }
  }

  Future<void> updateData(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    if (where != null && whereArgs != null) {
      await update(table, data, where, whereArgs);
    }
  }

  Future<void> deleteData(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    if (where != null && whereArgs != null) {
      await delete(table, where, whereArgs);
    }
  }

  Future<void> execute(String sql) async {
    final db = await database;
    await db.execute(sql);
  }

  // Close database connection
  static Future<void> close() async {
    final db = await database;
    db.close();
  }
}