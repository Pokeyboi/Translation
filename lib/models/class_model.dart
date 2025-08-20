import 'package:uuid/uuid.dart';

class ClassModel {
  final String id;
  final String name;
  final String teacherId;
  final String? description;
  final String? grade;
  final String? subject;
  final List<String> studentIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassModel({
    String? id,
    required this.name,
    required this.teacherId,
    this.description,
    this.grade,
    this.subject,
    List<String>? studentIds,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        studentIds = studentIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher_id': teacherId,
      'description': description,
      'grade': grade,
      'subject': subject,
      'student_ids': studentIds.join(','),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      teacherId: json['teacher_id'],
      description: json['description'],
      grade: json['grade'],
      subject: json['subject'],
      studentIds: json['student_ids'] != null 
          ? (json['student_ids'] as String).split(',').where((id) => id.isNotEmpty).toList()
          : [],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  ClassModel copyWith({
    String? name,
    String? description,
    String? grade,
    String? subject,
    List<String>? studentIds,
    bool? isActive,
  }) {
    return ClassModel(
      id: id,
      name: name ?? this.name,
      teacherId: teacherId,
      description: description ?? this.description,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      studentIds: studentIds ?? this.studentIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class StudentModel {
  final String id;
  final String name;
  final String classId;
  final List<String> parentIds;
  final String? grade;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentModel({
    String? id,
    required this.name,
    required this.classId,
    List<String>? parentIds,
    this.grade,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        parentIds = parentIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'class_id': classId,
      'parent_ids': parentIds.join(','),
      'grade': grade,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['name'],
      classId: json['class_id'],
      parentIds: json['parent_ids'] != null 
          ? (json['parent_ids'] as String).split(',').where((id) => id.isNotEmpty).toList()
          : [],
      grade: json['grade'],
      notes: json['notes'],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  StudentModel copyWith({
    String? name,
    String? classId,
    List<String>? parentIds,
    String? grade,
    String? notes,
    bool? isActive,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      classId: classId ?? this.classId,
      parentIds: parentIds ?? this.parentIds,
      grade: grade ?? this.grade,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}