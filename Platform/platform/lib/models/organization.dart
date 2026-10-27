class Organization {
  const Organization({
    required this.id,
    required this.legalId,
    required this.legalName,
    required this.status,
    required this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    final legalId = json['legalId'];
    final legalName = json['legalName'];
    final status = json['status'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        legalId is! String ||
        legalName is! String ||
        status is! String ||
        createdAt is! String) {
      throw const FormatException('Respuesta de empresa no válida.');
    }
    return Organization(
      id: id,
      legalId: legalId,
      legalName: legalName,
      status: status,
      createdAt: DateTime.parse(createdAt),
    );
  }

  final String id;
  final String legalId;
  final String legalName;
  final String status;
  final DateTime createdAt;
}
