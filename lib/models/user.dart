// lib/models/user.dart

class User {
  final String id;
  final String username;
  final String email;
  final String role;

  User({
    required this.id,
    required this.username,
    String? email,
    this.role = 'admin',
  }) : email = email ?? username;
}
