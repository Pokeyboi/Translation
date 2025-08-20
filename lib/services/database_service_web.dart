import 'dart:async';
import '../models/user_model.dart';
import '../models/dictionary_entry.dart';
import '../models/message_model.dart';
import '../models/class_model.dart';
import '../models/audio_clip.dart';
import '../models/language_pack.dart';
import '../models/phrase_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // In-memory storage for web
  final Map<String, List<Map<String, dynamic>>> _memoryDb = {
    'users': [],
    'dictionary_entries': [],
    'messages': [],
    'classes': [],
    'students': [],
    'audio_clips': [],
    'message_attachments': [],
    'language_packs': [],
    'message_templates': [],
    'phrase_entries': [],
  };

  Future<void> initDatabase() async {
    // No initialization needed for in-memory DB
  }

  Future<List<Map<String, dynamic>>> query(String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    // Note: This is a simplified query implementation for web.
    // It only supports basic 'where' clauses with '=' operator.
    var results = List<Map<String, dynamic>>.from(_memoryDb[table] ?? []);

    if (where != null && whereArgs != null) {
      final clauses = where.split(' AND ');
      for (int i = 0; i < clauses.length; i++) {
        final parts = clauses[i].split(' = ?');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = whereArgs[i];
          results = results.where((row) => row[key] == value).toList();
        }
      }
    }
    
    if (limit != null) {
      results = results.take(limit).toList();
    }

    return results;
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    _memoryDb[table]?.add(data);
    return 1; // Simulate 1 row inserted
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final key = where.split(' = ?')[0].trim();
    final value = whereArgs[0];
    
    final tableData = _memoryDb[table];
    if (tableData == null) return 0;

    int updatedCount = 0;
    for (int i = 0; i < tableData.length; i++) {
      if (tableData[i][key] == value) {
        tableData[i] = {...tableData[i], ...data};
        updatedCount++;
      }
    }
    return updatedCount;
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final key = where.split(' = ?')[0].trim();
    final value = whereArgs[0];

    final tableData = _memoryDb[table];
    if (tableData == null) return 0;
    
    final initialLength = tableData.length;
    tableData.removeWhere((row) => row[key] == value);
    return initialLength - tableData.length;
  }

  // User-specific methods
  Future<UserModel?> getUserById(String id) async {
    final results = await query('users', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final results = await query('users', where: 'email = ?', whereArgs: [email]);
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }

  Future<String> saveUser(UserModel user) async {
    await insert('users', user.toJson());
    return user.id;
  }

  Future<void> updateUser(UserModel user) async {
    await update('users', user.toJson(), 'id = ?', [user.id]);
  }

  // Dictionary-specific methods
  Future<List<DictionaryEntry>> searchDictionary(String searchTerm, {String? languageCode, String? category}) async {
    var allEntries = (await query('dictionary_entries')).map((json) => DictionaryEntry.fromJson(json));
    
    if (languageCode != null) {
      allEntries = allEntries.where((e) => e.languageCode == languageCode);
    }
    if (category != null) {
      allEntries = allEntries.where((e) => e.category == category);
    }
    
    final lowerCaseQuery = searchTerm.toLowerCase();
    return allEntries.where((e) => 
      e.english.toLowerCase().contains(lowerCaseQuery) || 
      e.translation.toLowerCase().contains(lowerCaseQuery)
    ).toList();
  }

  Future<String> saveDictionaryEntry(DictionaryEntry entry) async {
    await insert('dictionary_entries', entry.toJson());
    return entry.id;
  }

  Future<void> updateDictionaryEntry(DictionaryEntry entry) async {
    await update('dictionary_entries', entry.toJson(), 'id = ?', [entry.id]);
  }
  
  Future<List<DictionaryEntry>> getDictionaryEntries({String? languageCode, String? category}) async {
     var results = await query('dictionary_entries');
     return results.map((json) => DictionaryEntry.fromJson(json)).toList();
  }

  // Phrase-specific methods
  Future<List<PhraseEntry>> searchPhrases(String query, {String? languageCode, String? category}) async {
    return []; // Placeholder
  }

  Future<List<PhraseEntry>> getAllPhrases(String languageCode) async {
    return []; // Placeholder
  }

  Future<String> savePhraseEntry(PhraseEntry entry) async {
    await insert('phrase_entries', entry.toJson());
    return entry.id;
  }

  Future<void> updatePhraseEntry(PhraseEntry entry) async {
    await update('phrase_entries', entry.toJson(), 'id = ?', [entry.id]);
  }

  Future<List<PhraseEntry>> getPhraseEntries({String? languageCode, String? category}) async {
    return []; // Placeholder
  }

  Future<void> deletePhraseEntry(String id) async {
    await delete('phrase_entries', 'id = ?', [id]);
  }

  // Language pack methods
  Future<List<LanguagePack>> getLanguagePacks() async {
    return []; // Placeholder
  }

  Future<void> saveLanguagePack(LanguagePack pack) async {
    await insert('language_packs', pack.toJson());
  }

  // Message-specific methods
  Future<String> saveMessage(MessageModel message) async {
    await insert('messages', message.toJson());
    return message.id;
  }

  Future<void> updateMessage(MessageModel message) async {
    await update('messages', message.toJson(), 'id = ?', [message.id]);
  }

  Future<List<MessageModel>> getMessages({String? userId, String? classId, String? category}) async {
    return []; // Placeholder
  }

  Future<void> close() async {
    // No-op for web
  }
}
