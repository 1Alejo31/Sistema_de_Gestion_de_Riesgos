import 'dart:convert';

import '../controllers/auth_controller.dart';
import '../models/api_failure.dart';
import '../models/company_information_data.dart';

/// Organization-scoped resources documented in docs/api/openapi.json.
class CompanyInformationService {
  const CompanyInformationService(this._auth);
  final AuthController _auth;
  static const resources = {
    'company-profile',
    'work-sites',
    'processes',
    'areas',
    'workforce-distribution',
    'third-parties',
    'information-findings',
    'memberships',
  };

  Future<dynamic> request(
    String organizationId,
    String resource, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    if (organizationId.isEmpty || !resources.contains(resource)) {
      throw const ApiFailure(ApiFailureKind.validation);
    }
    final response = await _auth.request(
      method,
      '/api/v1/organizations/${Uri.encodeComponent(organizationId)}/$resource',
      organizationId: organizationId,
      body: body,
      idempotencyKey: idempotencyKey,
      useServerErrorMessage: true,
    );
    try {
      if (response.statusCode != (method == 'POST' ? 201 : 200) ||
          response.headers['content-type']
                  ?.split(';')
                  .first
                  .trim()
                  .toLowerCase() !=
              'application/json') {
        throw const FormatException();
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      final data = decoded['data'];
      final isList =
          method == 'GET' &&
          const {
            'work-sites',
            'processes',
            'areas',
            'third-parties',
            'memberships',
          }.contains(resource);
      if (isList) {
        if (data is! List ||
            data.any((item) => item is! Map<String, dynamic>)) {
          throw const FormatException();
        }
        for (final item in data) {
          validateCompanyInformation(resource, item as Map<String, dynamic>);
          if (item['organizationId'] != null &&
              item['organizationId'] != organizationId) {
            throw const FormatException();
          }
        }
        return data.cast<Map<String, dynamic>>();
      }
      if (data is! Map<String, dynamic>) throw const FormatException();
      validateCompanyInformation(resource, data);
      if (data['organizationId'] != null &&
          data['organizationId'] != organizationId) {
        throw const FormatException();
      }
      return data;
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
