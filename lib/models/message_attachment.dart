import 'package:uuid/uuid.dart';

enum AttachmentType { audio, image, file }

class MessageAttachment {
  final String id;
  final String messageId;
  final AttachmentType type;
  final String? clipId; // For audio attachments
  final String? url; // For file/image attachments
  final String? displayLabel;
  final int? fileSizeBytes;
  final String? mimeType;
  final DateTime createdAt;

  MessageAttachment({
    String? id,
    required this.messageId,
    required this.type,
    this.clipId,
    this.url,
    this.displayLabel,
    this.fileSizeBytes,
    this.mimeType,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'type': type.name,
      'clip_id': clipId,
      'url': url,
      'display_label': displayLabel,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'],
      messageId: json['message_id'],
      type: AttachmentType.values.firstWhere((e) => e.name == json['type']),
      clipId: json['clip_id'],
      url: json['url'],
      displayLabel: json['display_label'],
      fileSizeBytes: json['file_size_bytes'],
      mimeType: json['mime_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  MessageAttachment copyWith({
    String? messageId,
    AttachmentType? type,
    String? clipId,
    String? url,
    String? displayLabel,
    int? fileSizeBytes,
    String? mimeType,
  }) {
    return MessageAttachment(
      id: id,
      messageId: messageId ?? this.messageId,
      type: type ?? this.type,
      clipId: clipId ?? this.clipId,
      url: url ?? this.url,
      displayLabel: displayLabel ?? this.displayLabel,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt,
    );
  }
}