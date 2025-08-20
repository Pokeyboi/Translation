import 'package:uuid/uuid.dart';

enum SpeakerRole { parent, teacher, native }

class AudioClip {
  final String id;
  final String entryId;
  final SpeakerRole speakerRole;
  final String userId;
  final String? studentId;
  final String? classId;
  final String languageCode;
  final String? variantLabel;
  final String? note;
  final int durationMs;
  final bool consentPublic;
  final bool isReference;
  final String storageUrl;
  final List<double>? waveformPeaks;
  final DateTime createdAt;

  AudioClip({
    String? id,
    required this.entryId,
    required this.speakerRole,
    required this.userId,
    this.studentId,
    this.classId,
    required this.languageCode,
    this.variantLabel,
    this.note,
    required this.durationMs,
    this.consentPublic = false,
    this.isReference = false,
    required this.storageUrl,
    this.waveformPeaks,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry_id': entryId,
      'speaker_role': speakerRole.name,
      'user_id': userId,
      'student_id': studentId,
      'class_id': classId,
      'language_code': languageCode,
      'variant_label': variantLabel,
      'note': note,
      'duration_ms': durationMs,
      'consent_public': consentPublic ? 1 : 0,
      'is_reference': isReference ? 1 : 0,
      'storage_url': storageUrl,
      'waveform_peaks': waveformPeaks?.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AudioClip.fromJson(Map<String, dynamic> json) {
    return AudioClip(
      id: json['id'],
      entryId: json['entry_id'],
      speakerRole: SpeakerRole.values.firstWhere((e) => e.name == json['speaker_role']),
      userId: json['user_id'],
      studentId: json['student_id'],
      classId: json['class_id'],
      languageCode: json['language_code'],
      variantLabel: json['variant_label'],
      note: json['note'],
      durationMs: json['duration_ms'],
      consentPublic: json['consent_public'] == 1,
      isReference: json['is_reference'] == 1,
      storageUrl: json['storage_url'],
      waveformPeaks: json['waveform_peaks'] != null 
          ? (json['waveform_peaks'] as String).split(',').map((e) => double.parse(e)).toList()
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  AudioClip copyWith({
    String? entryId,
    SpeakerRole? speakerRole,
    String? userId,
    String? studentId,
    String? classId,
    String? languageCode,
    String? variantLabel,
    String? note,
    int? durationMs,
    bool? consentPublic,
    bool? isReference,
    String? storageUrl,
    List<double>? waveformPeaks,
  }) {
    return AudioClip(
      id: id,
      entryId: entryId ?? this.entryId,
      speakerRole: speakerRole ?? this.speakerRole,
      userId: userId ?? this.userId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      languageCode: languageCode ?? this.languageCode,
      variantLabel: variantLabel ?? this.variantLabel,
      note: note ?? this.note,
      durationMs: durationMs ?? this.durationMs,
      consentPublic: consentPublic ?? this.consentPublic,
      isReference: isReference ?? this.isReference,
      storageUrl: storageUrl ?? this.storageUrl,
      waveformPeaks: waveformPeaks ?? this.waveformPeaks,
      createdAt: createdAt,
    );
  }
}