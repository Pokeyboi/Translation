import 'package:uuid/uuid.dart';

class LanguagePack {
  final String id;
  final String languageCode;
  final String languageName;
  final List<String> dialectLabels;
  final String version;
  final int entriesCount;
  final String audioBasePath;
  final String createdBy;
  final DateTime createdAt;
  final String license;
  final String? notes;
  final bool isActive;
  final DateTime installedAt;
  final bool allowMachineTranslation;
  final String? mtProvider;
  final Map<String, dynamic>? tokenizationRules;
  final Map<String, dynamic>? joinRules;
  final Map<String, String>? dateTimeFormats;

  LanguagePack({
    String? id,
    required this.languageCode,
    required this.languageName,
    List<String>? dialectLabels,
    required this.version,
    required this.entriesCount,
    required this.audioBasePath,
    required this.createdBy,
    DateTime? createdAt,
    this.license = 'CC BY-SA 4.0',
    this.notes,
    this.isActive = true,
    DateTime? installedAt,
    this.allowMachineTranslation = false,
    this.mtProvider,
    this.tokenizationRules,
    this.joinRules,
    this.dateTimeFormats,
  })  : id = id ?? const Uuid().v4(),
        dialectLabels = dialectLabels ?? [],
        createdAt = createdAt ?? DateTime.now(),
        installedAt = installedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language_code': languageCode,
      'language_name': languageName,
      'dialect_labels': dialectLabels.join(','),
      'version': version,
      'entries_count': entriesCount,
      'audio_base_path': audioBasePath,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'license': license,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'installed_at': installedAt.toIso8601String(),
      'allow_machine_translation': allowMachineTranslation ? 1 : 0,
      'mt_provider': mtProvider,
      'tokenization_rules': tokenizationRules,
      'join_rules': joinRules,
      'date_time_formats': dateTimeFormats,
    };
  }

  factory LanguagePack.fromJson(Map<String, dynamic> json) {
    return LanguagePack(
      id: json['id'],
      languageCode: json['language_code'],
      languageName: json['language_name'],
      dialectLabels: json['dialect_labels'] != null 
          ? (json['dialect_labels'] as String).split(',').where((label) => label.isNotEmpty).toList()
          : [],
      version: json['version'],
      entriesCount: json['entries_count'],
      audioBasePath: json['audio_base_path'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      license: json['license'],
      notes: json['notes'],
      isActive: json['is_active'] == 1,
      installedAt: DateTime.parse(json['installed_at']),
      allowMachineTranslation: json['allow_machine_translation'] == 1,
      mtProvider: json['mt_provider'],
      tokenizationRules: json['tokenization_rules'] as Map<String, dynamic>?,
      joinRules: json['join_rules'] as Map<String, dynamic>?,
      dateTimeFormats: json['date_time_formats'] != null 
          ? Map<String, String>.from(json['date_time_formats'] as Map)
          : null,
    );
  }

  factory LanguagePack.fromManifest(Map<String, dynamic> manifest) {
    return LanguagePack(
      languageCode: manifest['language_code'],
      languageName: manifest['language_name'],
      dialectLabels: List<String>.from(manifest['dialect_labels'] ?? []),
      version: manifest['version'],
      entriesCount: manifest['entries_count'],
      audioBasePath: manifest['audio_base_path'],
      createdBy: manifest['created_by'],
      createdAt: DateTime.parse(manifest['created_at']),
      license: manifest['license'] ?? 'CC BY-SA 4.0',
      notes: manifest['notes'],
    );
  }

  Map<String, dynamic> toManifest() {
    return {
      'language_code': languageCode,
      'language_name': languageName,
      'dialect_labels': dialectLabels,
      'version': version,
      'entries_count': entriesCount,
      'audio_base_path': audioBasePath,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'license': license,
      'notes': notes,
    };
  }

  LanguagePack copyWith({
    String? languageCode,
    String? languageName,
    List<String>? dialectLabels,
    String? version,
    int? entriesCount,
    String? audioBasePath,
    String? createdBy,
    DateTime? createdAt,
    String? license,
    String? notes,
    bool? isActive,
  }) {
    return LanguagePack(
      id: id,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      dialectLabels: dialectLabels ?? this.dialectLabels,
      version: version ?? this.version,
      entriesCount: entriesCount ?? this.entriesCount,
      audioBasePath: audioBasePath ?? this.audioBasePath,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      license: license ?? this.license,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      installedAt: installedAt,
    );
  }
}

class MessageTemplate {
  final String id;
  final String englishText;
  final String category;
  final List<String> tags;
  final bool isCommon;
  final DateTime createdAt;

  MessageTemplate({
    String? id,
    required this.englishText,
    required this.category,
    List<String>? tags,
    this.isCommon = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english_text': englishText,
      'category': category,
      'tags': tags.join(','),
      'is_common': isCommon ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: json['id'],
      englishText: json['english_text'],
      category: json['category'],
      tags: json['tags'] != null 
          ? (json['tags'] as String).split(',').where((tag) => tag.isNotEmpty).toList()
          : [],
      isCommon: json['is_common'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}