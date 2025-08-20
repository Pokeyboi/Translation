import 'package:uuid/uuid.dart';

enum UserRole { teacher, parent, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final String? preferredLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    String? id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.preferredLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phoneNumber': phoneNumber,
      'preferredLanguage': preferredLanguage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      phoneNumber: json['phoneNumber'],
      preferredLanguage: json['preferredLanguage'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? phoneNumber,
    String? preferredLanguage,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}