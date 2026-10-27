class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.id,
    required this.serverExpiresAt,
    required this.accessExpiresAt,
    this.passwordChangeRequired = false,
  });

  factory AuthSession.fromJson(
    Map<String, dynamic> json,
    DateTime requestStartedAt,
  ) {
    if (json['passwordChangeRequired'] != null &&
        json['passwordChangeRequired'] is! bool) {
      throw const FormatException('Invalid password change flag.');
    }
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final seconds = json['expiresIn'];
    final session = json['session'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty ||
        seconds is! int ||
        seconds <= 0 ||
        session is! Map<String, dynamic> ||
        session['id'] is! String ||
        (session['id'] as String).isEmpty ||
        session['expiresAt'] is! String) {
      throw const FormatException('Respuesta de sesión no válida.');
    }
    final expires = DateTime.tryParse(session['expiresAt'] as String);
    if (expires == null) {
      throw const FormatException('Expiración de sesión no válida.');
    }
    return AuthSession(
      passwordChangeRequired: json['passwordChangeRequired'] == true,
      accessToken: access,
      refreshToken: refresh,
      id: session['id'] as String,
      serverExpiresAt: expires.toUtc(),
      accessExpiresAt: requestStartedAt.toUtc().add(Duration(seconds: seconds)),
    );
  }

  // These opaque values are exclusively held in memory. Never serialize/log.
  final bool passwordChangeRequired;
  final String accessToken;
  final String refreshToken;
  final String id;
  final DateTime serverExpiresAt;
  final DateTime accessExpiresAt;

  @override
  String toString() => 'AuthSession([redacted])';
}
