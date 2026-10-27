import 'membership_options.dart';

class AccountMembership {
  const AccountMembership({
    required this.accountId,
    required this.email,
    required this.organizationId,
    required this.role,
    required this.scope,
  });
  final String accountId;
  final String email;
  final String organizationId;
  final String role;
  final MembershipScope scope;

  factory AccountMembership.fromJson(Map<String, dynamic> json) {
    final membership = json['membership'];
    final scope = membership is Map ? membership['scope'] : null;
    if (json['id'] is! String ||
        (json['id'] as String).isEmpty ||
        json['email'] is! String ||
        (json['email'] as String).isEmpty ||
        json['organizationId'] is! String ||
        (json['organizationId'] as String).isEmpty ||
        membership is! Map ||
        membership['status'] != 'ACTIVE' ||
        membership['role'] is! String ||
        (membership['role'] as String).isEmpty ||
        scope is! Map) {
      throw const FormatException('Respuesta de vinculación inválida.');
    }
    final type = scope['type'];
    final id = scope['id'];
    if (!['ORGANIZATION', 'SITE', 'PROCESS'].contains(type) ||
        (type != 'ORGANIZATION' && (id is! String || id.isEmpty))) {
      throw const FormatException('Alcance de vinculación inválido.');
    }
    return AccountMembership(
      accountId: json['id'] as String,
      email: json['email'] as String,
      organizationId: json['organizationId'] as String,
      role: membership['role'] as String,
      scope: MembershipScope(
        type as String,
        type == 'ORGANIZATION' ? null : id as String,
      ),
    );
  }
}
