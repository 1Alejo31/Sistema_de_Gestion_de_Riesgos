class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.roles,
    required this.status,
    required this.scope,
    required this.createdAt,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final roles = json['roles'];
    final status = json['status'];
    final scope = json['scope'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        email is! String ||
        roles is! List ||
        roles.any((role) => role is! String) ||
        status is! String ||
        scope is! String ||
        createdAt is! String) {
      throw const FormatException('Respuesta de cuentas no válida.');
    }
    return UserAccount(
      id: id,
      email: email,
      roles: List<String>.unmodifiable(roles.cast<String>()),
      status: status,
      scope: scope,
      createdAt: DateTime.parse(createdAt),
    );
  }

  final String id;
  final String email;
  final List<String> roles;
  final String status;
  final String scope;
  final DateTime createdAt;
}
