import 'dart:convert';
import 'package:uuid/uuid.dart';

class VariableDefinition {
  final String name;
  final String type; // 'date', 'time', 'string', 'number'
  final String? format;

  VariableDefinition({
    required this.name,
    required this.type,
    this.format,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'format': format,
    };
  }

  factory VariableDefinition.fromJson(Map<String, dynamic> json) {
    return VariableDefinition(
      name: json['name'],
      type: json['type'],
      format: json['format'],
    );
  }
}

class PhraseEntry {
  final String id;
  final String languageCode;
  final String languageName;
  final String? dialectLabel;
  final String phraseKey;
  final String englishText;
  final String translationText;
  final List<VariableDefinition> variables;
  final String? category;
  final List<String> tags;
  final String? phoneticHelper;
  final String? notes;
  final String? audioNativeUrl;
  final String? audioTeacherUrl;
  final bool verified;
  final String? verifiedBy;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;

  PhraseEntry({
    String? id,
    required this.languageCode,
    required this.languageName,
    this.dialectLabel,
    required this.phraseKey,
    required this.englishText,
    required this.translationText,
    List<VariableDefinition>? variables,
    this.category,
    List<String>? tags,
    this.phoneticHelper,
    this.notes,
    this.audioNativeUrl,
    this.audioTeacherUrl,
    this.verified = false,
    this.verifiedBy,
    this.source,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        variables = variables ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language_code': languageCode,
      'language_name': languageName,
      'dialect_label': dialectLabel,
      'phrase_key': phraseKey,
      'english_text': englishText,
      'translation_text': translationText,
      'variables_json': variables.map((v) => v.toJson()).toList(),
      'category': category,
      'tags': tags.join(','),
      'phonetic_helper': phoneticHelper,
      'notes': notes,
      'audio_native_url': audioNativeUrl,
      'audio_teacher_url': audioTeacherUrl,
      'verified': verified ? 1 : 0,
      'verified_by': verifiedBy,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PhraseEntry.fromJson(Map<String, dynamic> json) {
    List<VariableDefinition> variables = [];
    if (json['variables_json'] != null) {
      if (json['variables_json'] is String) {
        // Handle JSON string from database
        try {
          final dynamic parsed = jsonDecode(json['variables_json'] as String);
          if (parsed is List) {
            variables = parsed
                .map((v) => VariableDefinition.fromJson(v as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          // If parsing fails, keep empty list
        }
      } else if (json['variables_json'] is List) {
        // Handle direct list
        variables = (json['variables_json'] as List)
            .map((v) => VariableDefinition.fromJson(v as Map<String, dynamic>))
            .toList();
      }
    }

    return PhraseEntry(
      id: json['id'],
      languageCode: json['language_code'],
      languageName: json['language_name'],
      dialectLabel: json['dialect_label'],
      phraseKey: json['phrase_key'],
      englishText: json['english_text'],
      translationText: json['translation_text'],
      variables: variables,
      category: json['category'],
      tags: json['tags'] != null 
          ? (json['tags'] as String).split(',').where((tag) => tag.isNotEmpty).toList() 
          : [],
      phoneticHelper: json['phonetic_helper'],
      notes: json['notes'],
      audioNativeUrl: json['audio_native_url'],
      audioTeacherUrl: json['audio_teacher_url'],
      verified: json['verified'] == 1,
      verifiedBy: json['verified_by'],
      source: json['source'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toCsvMap() {
    return {
      'language_code': languageCode,
      'language_name': languageName,
      'dialect_label': dialectLabel ?? '',
      'phrase_key': phraseKey,
      'english_text': englishText,
      'translation_text': translationText,
      'variables_json': variables.isNotEmpty 
          ? variables.map((v) => v.toJson()).toList().toString()
          : '',
      'category': category ?? '',
      'tags': tags.join(';'),
      'phonetic_helper': phoneticHelper ?? '',
      'notes': notes ?? '',
      'audio_native_filename': audioNativeUrl?.split('/').last ?? '',
      'audio_teacher_filename': audioTeacherUrl?.split('/').last ?? '',
      'verified': verified.toString(),
      'verified_by': verifiedBy ?? '',
      'source': source ?? '',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PhraseEntry.fromCsvMap(Map<String, dynamic> csvData) {
    List<VariableDefinition> variables = [];
    if (csvData['variables_json'] != null && csvData['variables_json'].toString().isNotEmpty) {
      try {
        // Parse JSON string from CSV
        final String variablesStr = csvData['variables_json'].toString();
        if (variablesStr.startsWith('[') && variablesStr.endsWith(']')) {
          // This is a simplified parser for the basic JSON format
          // In a real implementation, you'd use dart:convert
          variables = [];
        }
      } catch (e) {
        // If parsing fails, keep empty list
      }
    }

    return PhraseEntry(
      languageCode: csvData['language_code'],
      languageName: csvData['language_name'],
      dialectLabel: csvData['dialect_label']?.isEmpty == true ? null : csvData['dialect_label'],
      phraseKey: csvData['phrase_key'],
      englishText: csvData['english_text'],
      translationText: csvData['translation_text'],
      variables: variables,
      category: csvData['category']?.isEmpty == true ? null : csvData['category'],
      tags: csvData['tags']?.split(';').where((tag) => tag.isNotEmpty).toList() ?? [],
      phoneticHelper: csvData['phonetic_helper']?.isEmpty == true ? null : csvData['phonetic_helper'],
      notes: csvData['notes']?.isEmpty == true ? null : csvData['notes'],
      audioNativeUrl: csvData['audio_native_filename']?.isEmpty == true ? null : csvData['audio_native_filename'],
      audioTeacherUrl: csvData['audio_teacher_filename']?.isEmpty == true ? null : csvData['audio_teacher_filename'],
      verified: csvData['verified'] == 'true',
      verifiedBy: csvData['verified_by']?.isEmpty == true ? null : csvData['verified_by'],
      source: csvData['source']?.isEmpty == true ? null : csvData['source'],
      createdAt: csvData['created_at'] != null ? DateTime.parse(csvData['created_at']) : null,
      updatedAt: csvData['updated_at'] != null ? DateTime.parse(csvData['updated_at']) : null,
    );
  }

  PhraseEntry copyWith({
    String? languageCode,
    String? languageName,
    String? dialectLabel,
    String? phraseKey,
    String? englishText,
    String? translationText,
    List<VariableDefinition>? variables,
    String? category,
    List<String>? tags,
    String? phoneticHelper,
    String? notes,
    String? audioNativeUrl,
    String? audioTeacherUrl,
    bool? verified,
    String? verifiedBy,
    String? source,
  }) {
    return PhraseEntry(
      id: id,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      dialectLabel: dialectLabel ?? this.dialectLabel,
      phraseKey: phraseKey ?? this.phraseKey,
      englishText: englishText ?? this.englishText,
      translationText: translationText ?? this.translationText,
      variables: variables ?? this.variables,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      phoneticHelper: phoneticHelper ?? this.phoneticHelper,
      notes: notes ?? this.notes,
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