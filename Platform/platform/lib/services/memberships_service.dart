import 'dart:convert';

import 'package:http/http.dart' as http;

import '../controllers/auth_controller.dart';
import '../models/api_failure.dart';
import '../models/membership_options.dart';
import '../models/account_membership.dart';

class MembershipsService {
  const MembershipsService(this._auth);
  final AuthController _auth;

  dynamic _data(http.Response response, int expectedStatus) {
    try {
      if (response.statusCode != expectedStatus ||
          response.headers['content-type']
                  ?.split(';')
                  .first
                  .trim()
                  .toLowerCase() !=
              'application/json') {
        throw const FormatException();
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic> || body['data'] == null) {
        throw const FormatException();
      }
      return body['data'];
    } on FormatException {
      throw ApiFailure(
        ApiFailureKind.unexpected,
        statusCode: response.statusCode,
        correlationId: ApiFailure.safeCorrelationId(
          response.headers['x-correlation-id'],
        ),
      );
    }
  }

  Future<List<OrganizationRole>> roles() async {
    final data = _data(
      await _auth.request('GET', '/api/v1/roles', useServerErrorMessage: true),
      200,
    );
    if (data is! List ||
        data.any(
          (item) =>
              item is! Map ||
              item['role'] is! String ||
              (item['role'] as String).isEmpty,
        )) {
      throw const ApiFailure(ApiFailureKind.unexpected);
    }
    return [for (final item in data) OrganizationRole(item['role'] as String)];
  }

  Future<List<MembershipScope>> scopes(String organizationId) async {
    final data = _data(
      await _auth.request(
        'GET',
        '/api/v1/organizations/${Uri.encodeComponent(organizationId)}/memberships',
        useServerErrorMessage: true,
      ),
      200,
    );
    if (data is! List) throw const ApiFailure(ApiFailureKind.unexpected);
    final scopes = <String, MembershipScope>{
      'ORGANIZATION:': const MembershipScope('ORGANIZATION'),
    };
    for (final membership in data) {
      if (membership is! Map || membership['scope'] is! Map) {
        throw const ApiFailure(ApiFailureKind.unexpected);
      }
      final scope = membership['scope'] as Map;
      final type = scope['type'];
      final id = scope['id'];
      if (type == 'ORGANIZATION') continue;
      if ((type != 'SITE' && type != 'PROCESS') ||
          id is! String ||
          id.isEmpty) {
        throw const ApiFailure(ApiFailureKind.unexpected);
      }
      final option = MembershipScope(type as String, id);
      scopes[option.key] = option;
    }
    return scopes.values.toList();
  }

  Future<AccountMembership> link({
    required String organizationId,
    required String email,
    required String role,
    MembershipScope scope = const MembershipScope('ORGANIZATION'),
    required String idempotencyKey,
  }) async {
    final http.Response response;
    try {
      response = await _auth.request(
        'POST',
        '/api/v1/organizations/${Uri.encodeComponent(organizationId)}/memberships',
        body: {'email': email, 'role': role, 'scope': scope.toJson()},
        idempotencyKey: idempotencyKey,
        useServerErrorMessage: true,
      );
    } on ApiFailure catch (error) {
      if ((error.statusCode ?? 0) >= 500) {
        throw ApiFailure(
          ApiFailureKind.unexpected,
          statusCode: error.statusCode,
          correlationId: error.correlationId,
        );
      }
      rethrow;
    }
    final data = _data(response, 201);
    try {
      if (data is! Map<String, dynamic>) throw const FormatException();
      final linked = AccountMembership.fromJson(data);
      if (linked.organizationId != organizationId ||
          linked.email.toLowerCase() != email.toLowerCase() ||
          linked.role != role ||
          linked.scope.key != scope.key) {
        throw const FormatException();
      }
      return linked;
    } on FormatException {
      throw ApiFailure(
        ApiFailureKind.unexpected,
        statusCode: response.statusCode,
        correlationId: ApiFailure.safeCorrelationId(
          response.headers['x-correlation-id'],
        ),
      );
    }
  }
}
