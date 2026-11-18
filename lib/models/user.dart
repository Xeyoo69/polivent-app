import '../utils/json_helper.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.nim,
    required this.email,
    required this.role,
    this.registrationsCount,
  });

  final int id;
  final String name;
  final String nim;
  final String email;
  final String role;
  final int? registrationsCount;

  bool get isAdmin => role == 'admin';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: jsonInt(json['id']),
      name: jsonString(json['name'], 'Pengguna'),
      nim: jsonString(json['nim']),
      email: jsonString(json['email']),
      role: jsonString(json['role'], 'user'),
      registrationsCount: json['registrations_count'] == null
          ? null
          : jsonInt(json['registrations_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nim': nim,
      'email': email,
      'role': role,
      'registrations_count': registrationsCount,
    };
  }
}
