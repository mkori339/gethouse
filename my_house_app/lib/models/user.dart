// lib/models/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String? status;      // optional (e.g., "active", "blocked", etc.)
  final String? createdAt;   // optional ISO string or timestamp string

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    this.status,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is double) return v.toInt();
    return 0;
  }
}
