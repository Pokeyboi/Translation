import 'package:uuid/uuid.dart';

class DictionaryEntry {
  final String id;
  final String languageCode;
  final String languageName;
  final String? dialectLabel;
  final String english;
  final String translation;
  final String? phoneticHelper;
  final String? notes;
  final String? category;
  final List<String> tags;
  final String? audioNativeUrl;
  final String? audioTeacherUrl;
  final bool verified;
  final String? verifiedBy;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? senseId;
  final String? partOfSpeech;
  final List<String> synonyms;
  final List<String> examples;

  DictionaryEntry({
    String? id,
    required this.languageCode,
    required this.languageName,
    this.dialectLabel,
    required this.english,
    required this.translation,
    this.phoneticHelper,
    this.notes,
    this.category,
    List<String>? tags,
    this.audioNativeUrl,
    this.audioTeacherUrl,
    this.verified = false,
    this.verifiedBy,
    this.source,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.senseId,
    this.partOfSpeech,
    List<String>? synonyms,
    List<String>? examples,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        synonyms = synonyms ?? [],
        examples = examples ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language_code': languageCode,
      'language_name': languageName,
      'dialect_label': dialectLabel,
      'english': english,
      'translation': translation,
      'phonetic_helper': phoneticHelper,
      'notes': notes,
      'category': category,
      'tags': tags.join(','),
      'audio_native_url': audioNativeUrl,
      'audio_teacher_url': audioTeacherUrl,
      'verified': verified ? 1 : 0,
      'verified_by': verifiedBy,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sense_id': senseId,
      'part_of_speech': partOfSpeech,
      'synonyms': synonyms.join(','),
      'examples': examples.join('||'),
    };
  }

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      id: json['id'],
      languageCode: json['language_code'],
      languageName: json['language_name'],
      dialectLabel: json['dialect_label'],
      english: json['english'],
      translation: json['translation'],
      phoneticHelper: json['phonetic_helper'],
      notes: json['notes'],
      category: json['category'],
      tags: json['tags'] != null ? (json['tags'] as String).split(',').where((tag) => tag.isNotEmpty).toList() : [],
      audioNativeUrl: json['audio_native_url'],
      audioTeacherUrl: json['audio_teacher_url'],
      verified: json['verified'] == 1,
      verifiedBy: json['verified_by'],
      source: json['source'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      senseId: json['sense_id'],
      partOfSpeech: json['part_of_speech'],
      synonyms: json['synonyms'] != null 
          ? (json['synonyms'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      examples: json['examples'] != null 
          ? (json['examples'] as String).split('||').where((e) => e.isNotEmpty).toList()
          : [],
    );
  }

  Map<String, dynamic> toCsvMap() {
    return {
      'language_code': languageCode,
      'language_name': languageName,
      'dialect_label': dialectLabel ?? '',
      'english': english,
      'translation': translation,
      'phonetic_helper': phoneticHelper ?? '',
      'notes': notes ?? '',
      'category': category ?? '',
      'tags': tags.join(';'),
      'audio_native_filename': audioNativeUrl?.split('/').last ?? '',
      'audio_teacher_filename': audioTeacherUrl?.split('/').last ?? '',
      'verified': verified.toString(),
      'verified_by': verifiedBy ?? '',
      'source': source ?? '',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DictionaryEntry.fromCsvMap(Map<String, dynamic> csvData) {
    return DictionaryEntry(
      languageCode: csvData['language_code'],
      languageName: csvData['language_name'],
      dialectLabel: csvData['dialect_label']?.isEmpty == true ? null : csvData['dialect_label'],
      english: csvData['english'],
      translation: csvData['translation'],
      phoneticHelper: csvData['phonetic_helper']?.isEmpty == true ? null : csvData['phonetic_helper'],
      notes: csvData['notes']?.isEmpty == true ? null : csvData['notes'],
      category: csvData['category']?.isEmpty == true ? null : csvData['category'],
      tags: csvData['tags']?.split(';').where((tag) => tag.isNotEmpty).toList() ?? [],
      audioNativeUrl: csvData['audio_native_filename']?.isEmpty == true ? null : csvData['audio_native_filename'],
      audioTeacherUrl: csvData['audio_teacher_filename']?.isEmpty == true ? null : csvData['audio_teacher_filename'],
      verified: csvData['verified'] == 'true',
      verifiedBy: csvData['verified_by']?.isEmpty == true ? null : csvData['verified_by'],
      source: csvData['source']?.isEmpty == true ? null : csvData['source'],
      createdAt: csvData['created_at'] != null ? DateTime.parse(csvData['created_at']) : null,
      updatedAt: csvData['updated_at'] != null ? DateTime.parse(csvData['updated_at']) : null,
    );
  }

  DictionaryEntry copyWith({
    String? languageCode,
    String? languageName,
    String? dialectLabel,
    String? english,
    String? translation,
    String? phoneticHelper,
    String? notes,
    String? category,
    List<String>? tags,
    String? audioNativeUrl,
    String? audioTeacherUrl,
    bool? verified,
    String? verifiedBy,
    String? source,
  }) {
    return DictionaryEntry(
      id: id,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      dialectLabel: dialectLabel ?? this.dialectLabel,
      english: english ?? this.english,
      translation: translation ?? this.translation,
      phoneticHelper: phoneticHelper ?? this.phoneticHelper,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      audioNativeUrl: audioNativeUrl ?? this.audioNativeUrl,
      audioTeacherUrl: audioTeacherUrl ?? this.audioTeacherUrl,
      verified: verified ?? this.verified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      source: source ?? this.source,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}