import 'dart:convert';

import '../controllers/auth_controller.dart';
import '../models/api_failure.dart';
import '../models/organization.dart';

class OrganizationsService {
  const OrganizationsService(this._auth);

  final AuthController _auth;

  Future<List<Organization>> listOrganizations() async {
    final response = await _auth.request('GET', '/api/v1/organizations');
    try {
      if (response.statusCode != 200 || !_isJson(response)) {
        throw const FormatException('Respuesta de empresas no válida.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['data'] == null) {
        throw const FormatException('Respuesta de empresas no válida.');
      }
      final data = decoded['data'];
      final items = data is List
          ? data
          : data is Map<String, dynamic>
          ? data['items']
          : null;
      if (items is! List) {
        throw const FormatException('Respuesta de empresas no válida.');
      }
      return List<Organization>.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Respuesta de empresas no válida.');
          }
          return Organization.fromJson(item);
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

  Future<Organization> createOrganization({
    required String legalId,
    required String legalName,
    required String administratorId,
  }) async {
    final response = await _auth.request(
      'POST',
      '/api/v1/organizations',
      body: {
        'legalId': legalId.trim(),
        'legalName': legalName.trim(),
        'administratorId': administratorId,
      },
      useServerErrorMessage: true,
    );
    try {
      if (response.statusCode != 201 || !_isJson(response)) {
        throw const FormatException('Respuesta de creación no válida.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['data'] is! Map<String, dynamic>) {
        throw const FormatException('Respuesta de creación no válida.');
      }
      return Organization.fromJson(decoded['data'] as Map<String, dynamic>);
    } on FormatException {
      throw ApiFailure(
        ApiFailureKind.unexpected,
        correlationId: ApiFailure.safeCorrelationId(
          response.headers['x-correlation-id'],
        ),
      );
    }
  }

  bool _isJson(dynamic response) =>
      response.headers['content-type']?.split(';').first.trim().toLowerCase() ==
      'application/json';
}
