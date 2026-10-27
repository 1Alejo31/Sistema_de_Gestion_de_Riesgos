/// Validates the fields rendered by the company workspace before UI access.
void validateCompanyInformation(String resource, Map<String, dynamic> data) {
  void strings(List<String> fields) {
    if (fields.any((field) => data[field] is! String)) {
      throw const FormatException('Respuesta de empresa no válida.');
    }
  }

  bool optionalText(dynamic value) => value == null || value is String;
  bool maps(dynamic value) =>
      value is List && value.every((item) => item is Map<String, dynamic>);
  switch (resource) {
    case 'company-profile':
      final contact = data['contact'];
      final activities = data['economicActivities'];
      if (!optionalText(data['commercialName']) ||
          contact is! Map ||
          !optionalText(contact['email']) ||
          !optionalText(contact['phone']) ||
          !maps(activities) ||
          (activities as List).any(
            (item) =>
                item['code'] is! String ||
                item['description'] is! String ||
                item['isPrimary'] is! bool ||
                !optionalText(item['classificationTable']),
          )) {
        throw const FormatException();
      }
      strings(['status']);
    case 'work-sites':
      strings(['id', 'name', 'type', 'municipality', 'address', 'status']);
    case 'processes' || 'areas':
      strings(['id', 'name', 'status']);
    case 'workforce-distribution':
      final entries = data['entries'];
      if (!maps(entries) ||
          (entries as List).any(
            (item) =>
                [
                  'relationshipType',
                  'jobTitle',
                  'shift',
                  'workSchedule',
                ].any((key) => item[key] is! String) ||
                item['workerCount'] is! int ||
                !optionalText(item['workSiteId']) ||
                !optionalText(item['areaId']),
          )) {
        throw const FormatException();
      }
    case 'third-parties':
      strings(['id', 'legalName', 'taxIdentifier', 'description', 'status']);
      if (data['relationshipTypes'] is! List ||
          (data['relationshipTypes'] as List).any(
            (item) => item != 'CONTRACTOR' && item != 'SUPPLIER',
          )) {
        throw const FormatException();
      }
    case 'information-findings':
      final findings = data['findings'];
      if (!maps(findings) ||
          (findings as List).any(
            (item) => item['message'] is! String || item['section'] is! String,
          )) {
        throw const FormatException();
      }
    case 'memberships':
      if (!optionalText(data['email'])) throw const FormatException();
      strings(['role']);
  }
  if ((resource == 'company-profile' || resource == 'workforce-distribution') &&
      data['version'] != null &&
      data['version'] is! int) {
    throw const FormatException();
  }
}
