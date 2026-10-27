class OrganizationRole {
  const OrganizationRole(this.code);
  final String code;
  String get label => switch (code) {
    'ORGANIZATION_ADMIN' => 'Administrador de empresa',
    'SST_MANAGER' => 'Responsable de SST',
    'EXECUTIVE' => 'Directivo',
    'WORKER' => 'Trabajador',
    'CONTRACTOR' => 'Contratista',
    'COPASST' => 'COPASST',
    'AUDITOR' => 'Auditor',
    'CONSULTANT' => 'Consultor',
    'OBSERVER' => 'Observador',
    _ => code,
  };
}

class MembershipScope {
  const MembershipScope(this.type, [this.id]);
  final String type;
  final String? id;
  String get key => '$type:${id ?? ''}';
  String get label => switch (type) {
    'ORGANIZATION' => 'Toda la empresa',
    'SITE' => 'Sede · $id',
    'PROCESS' => 'Proceso · $id',
    _ => type,
  };
  Map<String, dynamic> toJson() => {'type': type, if (id != null) 'id': id};
}
