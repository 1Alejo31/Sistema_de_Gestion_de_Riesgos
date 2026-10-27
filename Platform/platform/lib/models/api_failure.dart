enum ApiFailureKind {
  configuration,
  validation,
  unauthorized,
  forbidden,
  rateLimit,
  network,
  unexpected,
}

class ApiFailure implements Exception {
  const ApiFailure(
    this.kind, {
    this.correlationId,
    this.serverMessage,
    this.statusCode,
  });

  final ApiFailureKind kind;
  final String? correlationId;
  final String? serverMessage;
  final int? statusCode;

  String get message =>
      serverMessage ??
      switch (kind) {
        ApiFailureKind.configuration =>
          'El servicio de acceso no está configurado. Contacta con soporte.',
        ApiFailureKind.validation =>
          'Revisa los datos ingresados e intenta nuevamente.',
        ApiFailureKind.unauthorized =>
          'No se pudo autorizar el acceso. Revisa tus credenciales; la cuenta también puede estar bloqueada o inactiva.',
        ApiFailureKind.forbidden =>
          'No tienes autorización para realizar esta acción.',
        ApiFailureKind.rateLimit =>
          'Hay demasiadas solicitudes. Espera antes de intentar nuevamente.',
        ApiFailureKind.network =>
          'No pudimos conectar con el servicio. Revisa tu conexión e intenta nuevamente.',
        ApiFailureKind.unexpected =>
          'El servicio no pudo completar la solicitud. Intenta más tarde.',
      };

  String get supportMessage => serverMessage != null || correlationId == null
      ? message
      : '$message Referencia para soporte: $correlationId';

  static String? safeCorrelationId(Object? value) =>
      value is String && RegExp(r'^[A-Za-z0-9._:-]{8,128}$').hasMatch(value)
      ? value
      : null;

  @override
  String toString() => 'ApiFailure(${kind.name})';
}
