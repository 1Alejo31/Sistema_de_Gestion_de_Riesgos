class AuthIdentity {
  const AuthIdentity({
    required this.id,
    required this.email,
    required this.status,
    required this.roles,
    required this.scope,
    this.passwordChangeRequired = false,
  });

  factory AuthIdentity.fromJson(Map<String, dynamic> json) {
    for (final field in ['id', 'email', 'status', 'scope']) {
      if (json[field] is! String || (json[field] as String).isEmpty) {
        throw const FormatException('Respuesta de identidad no válida.');
      }
    }
    if (json['passwordChangeRequired'] != null &&
        json['passwordChangeRequired'] is! bool) {
      throw const FormatException('Invalid password change flag.');
    }
    final roles = json['roles'];
    if (roles is! List || roles.any((role) => role is! String)) {
      throw const FormatException('Roles de identidad no válidos.');
    }
    return AuthIdentity(
      id: json['id'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      roles: List<String>.unmodifiable(roles.cast<String>()),
      scope: json['scope'] as String,
      passwordChangeRequired: json['passwordChangeRequired'] == true,
    );
  }

  final String id;
  final String email;
  final String status;
  final List<String> roles;
  final String scope;
  final bool passwordChangeRequired;
  bool get isSuperAdmin => roles.contains('SUPER_ADMIN');
}
