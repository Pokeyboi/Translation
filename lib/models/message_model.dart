import 'package:uuid/uuid.dart';

enum MessageStatus { draft, sent, delivered, read, failed }
enum MessageType { text, audio, image, pdf, template }

class MessageModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String? classId;
  final String? studentId;
  final String englishText;
  final String translatedText;
  final String languageCode;
  final MessageType type;
  final MessageStatus status;
  final String? templateId;
  final List<String> attachmentUrls;
  final String? audioEnglishUrl;
  final String? audioTranslatedUrl;
  final String? category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  MessageModel({
    String? id,
    required this.senderId,
    required this.recipientId,
    this.classId,
    this.studentId,
    required this.englishText,
    required this.translatedText,
    required this.languageCode,
    this.type = MessageType.text,
    this.status = MessageStatus.draft,
    this.templateId,
    List<String>? attachmentUrls,
    this.audioEnglishUrl,
    this.audioTranslatedUrl,
    this.category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
  })  : id = id ?? const Uuid().v4(),
        attachmentUrls = attachmentUrls ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'class_id': classId,
      'student_id': studentId,
      'english_text': englishText,
      'translated_text': translatedText,
      'language_code': languageCode,
      'type': type.name,
      'status': status.name,
      'template_id': templateId,
      'attachment_urls': attachmentUrls.join(','),
      'audio_english_url': audioEnglishUrl,
      'audio_translated_url': audioTranslatedUrl,
      'category': category,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      recipientId: json['recipient_id'],
      classId: json['class_id'],
      studentId: json['student_id'],
      englishText: json['english_text'],
      translatedText: json['translated_text'],
      languageCode: json['language_code'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
      templateId: json['template_id'],
      attachmentUrls: json['attachment_urls'] != null 
          ? (json['attachment_urls'] as String).split(',').where((url) => url.isNotEmpty).toList()
          : [],
      audioEnglishUrl: json['audio_english_url'],
      audioTranslatedUrl: json['audio_translated_url'],
      category: json['category'],
      tags: json['tags'] != null 
          ? (json['tags'] as String).split(',').where((tag) => tag.isNotEmpty).toList()
          : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  MessageModel copyWith({
    String? recipientId,
    String? classId,
    String? studentId,
    String? englishText,
    String? translatedText,
    String? languageCode,
    MessageType? type,
    MessageStatus? status,
    String? templateId,
    List<String>? attachmentUrls,
    String? audioEnglishUrl,
    String? audioTranslatedUrl,
    String? category,
    List<String>? tags,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      recipientId: recipientId ?? this.recipientId,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      englishText: englishText ?? this.englishText,
      translatedText: translatedText ?? this.translatedText,
      languageCode: languageCode ?? this.languageCode,
      type: type ?? this.type,
      status: status ?? this.status,
      templateId: templateId ?? this.templateId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      audioEnglishUrl: audioEnglishUrl ?? this.audioEnglishUrl,
      audioTranslatedUrl: audioTranslatedUrl ?? this.audioTranslatedUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}