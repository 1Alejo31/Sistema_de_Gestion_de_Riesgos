import 'dart:convert';
import 'dart:math';

import '../controllers/auth_controller.dart';
import '../models/api_failure.dart';
import '../models/user_account.dart';

class UsersService {
  const UsersService(this._auth);

  final AuthController _auth;

  Future<List<UserAccount>> listUsers() async {
    final response = await _auth.request('GET', '/api/v1/users');
    try {
      if (response.statusCode != 200 ||
          response.headers['content-type']
                  ?.split(';')
                  .first
                  .trim()
                  .toLowerCase() !=
              'application/json') {
        throw const FormatException('Respuesta de cuentas no válida.');
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic> ||
          json['data'] is! Map<String, dynamic> ||
          json['data']['items'] is! List) {
        throw const FormatException('Respuesta de cuentas no válida.');
      }
      final items = json['data']['items'] as List;
      return List<UserAccount>.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Respuesta de cuentas no válida.');
          }
          return UserAccount.fromJson(item);
        }),
      );
    } on FormatException {
      throw ApiFailure(
        ApiFailureKind.unexpected,
        correlationId: ApiFailure.safeCorrelationId(
          response.headers['x-correlation-id'],
        ),
      );
    }
  }

  Future<UserAccount> createUser({
    required String email,
    required String password,
    required String idempotencyKey,
  }) async {
    final response = await _auth.request(
      'POST',
      '/api/v1/users',
      body: {'email': email.trim(), 'password': password},
      idempotencyKey: idempotencyKey,
      useServerErrorMessage: true,
    );
    try {
      if (response.statusCode != 201 ||
          response.headers['content-type']
                  ?.split(';')
                  .first
                  .trim()
                  .toLowerCase() !=
              'application/json') {
        throw const FormatException('Respuesta de creación no válida.');
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic> ||
          json['data'] is! Map<String, dynamic>) {
        throw const FormatException('Respuesta de creación no válida.');
      }
      return UserAccount.fromJson(json['data'] as Map<String, dynamic>);
    } on FormatException {
      throw ApiFailure(
        ApiFailureKind.unexpected,
        correlationId: ApiFailure.safeCorrelationId(
          response.headers['x-correlation-id'],
        ),
      );
    }
  }

  static String newIdempotencyKey({Random? random}) {
    final source = random ?? Random.secure();
    return List.generate(
      32,
      (_) => source.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
