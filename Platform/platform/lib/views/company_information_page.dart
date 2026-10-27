import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../models/account_form_validators.dart';
import '../models/api_failure.dart';
import '../models/membership_options.dart';
import '../models/organization.dart';
import '../providers/company_information_providers.dart';
import '../providers/memberships_providers.dart';
import '../providers/organizations_providers.dart';
import '../services/users_service.dart';
import '../widgets/operation_success_dialog.dart';
import '../widgets/company_workspace_design.dart';
import '../widgets/searchable_choice_field.dart';

class CompanyInformationPage extends ConsumerWidget {
  const CompanyInformationPage({super.key, this.bottomPadding = 18});
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organization = ref.watch(selectedOrganizationProvider);
    return organization == null
        ? const CompanySelectionWelcome()
        : _CompanyWorkspace(
            key: ValueKey(organization.id),
            organization: organization,
            bottomPadding: bottomPadding,
          );
  }
}

class _CompanyWorkspace extends StatefulWidget {
  const _CompanyWorkspace({
    super.key,
    required this.organization,
    required this.bottomPadding,
  });
  final Organization organization;
  final double bottomPadding;
  @override
  State<_CompanyWorkspace> createState() => _CompanyWorkspaceState();
}

class _CompanyWorkspaceState extends State<_CompanyWorkspace> {
  int _tab = 0;
  final Set<int> _visited = {0};

  void _select(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _tab = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CompanyContextCard(organization: widget.organization, compact: _tab > 1),
      Expanded(
        child: CompanyFolder(
          selected: _tab,
          onSelected: _select,
          child: IndexedStack(
            index: _tab,
            children: [
              for (var i = 0; i < companySections.length; i++)
                _visited.contains(i)
                    ? SingleChildScrollView(
                        key: PageStorageKey('company_section_$i'),
                        primary: false,
                        padding: EdgeInsets.fromLTRB(
                          18,
                          22,
                          18,
                          widget.bottomPadding,
                        ),
                        child: i < 2
                            ? CompanyOverview(
                                organization: widget.organization,
                                onSelected: _select,
                                identificationOnly: i == 1,
                              )
                            : _CompanySection(
                                organization: widget.organization,
                                tab: i,
                                active: i == _tab,
                              ),
                      )
                    : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    ],
  );
}

class _CompanySection extends ConsumerStatefulWidget {
  const _CompanySection({
    required this.organization,
    required this.tab,
    required this.active,
  });
  final Organization organization;
  final int tab;
  final bool active;
  @override
  ConsumerState<_CompanySection> createState() => _CompanySectionState();
}

class _CompanySectionState extends ConsumerState<_CompanySection> {
  final _fields = <String, TextEditingController>{};
  final _forms = <String, GlobalKey<FormState>>{};
  final _data = <String, dynamic>{};
  final _sets = <String, Set<String>>{};
  final _choices = <String, String>{};
  final List<_Activity> _activities = [_Activity()];
  final List<Map<String, dynamic>> _groups = [];
  String? _error;
  String? _readError;
  bool _loading = true;
  bool _busy = false;
  bool _groupsDirty = false;
  int _primary = 0;
  String? _pendingFingerprint;
  String? _idempotencyKey;
  String get _id => widget.organization.id;
  TextEditingController _controller(String name) =>
      _fields.putIfAbsent(name, TextEditingController.new);
  String _value(String name) => _controller(name).text.trim();
  GlobalKey<FormState> _form(String name) =>
      _forms.putIfAbsent(name, GlobalKey<FormState>.new);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _CompanySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        !oldWidget.active &&
        !_busy &&
        !_loading &&
        (widget.tab == 4 || widget.tab == 5)) {
      _refreshReferences();
    }
  }

  Future<void> _refreshReferences() async {
    setState(() => _busy = true);
    try {
      final resources = widget.tab == 4
          ? ['processes', 'work-sites']
          : ['areas', 'work-sites'];
      final service = ref.read(companyInformationServiceProvider);
      final results = await Future.wait([
        for (final resource in resources) service.request(_id, resource),
      ]);
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < resources.length; i++) {
          _data[resources[i]] = results[i];
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    for (final activity in _activities) {
      activity.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _items(String resource) =>
      (_data[resource] as List?)?.cast<Map<String, dynamic>>() ?? [];
  Map<String, dynamic> _object(String resource) =>
      (_data[resource] as Map<String, dynamic>?) ?? {};
  List<Map<String, dynamic>> _active(String resource) =>
      _items(resource).where((item) => item['status'] == 'ACTIVE').toList();
  String _message(Object error) => error is ApiFailure
      ? error.supportMessage
      : 'No se pudo completar la operación. Vuelve a intentarlo.';

  Future<void> _load({bool hydrate = true}) async {
    setState(() {
      _loading = true;
      _readError = null;
    });
    final resources = switch (widget.tab) {
      2 => ['company-profile'],
      3 => ['work-sites'],
      4 => ['processes', 'areas', 'work-sites'],
      5 => ['workforce-distribution', 'work-sites', 'areas'],
      6 => ['third-parties'],
      8 => ['memberships'],
      _ => <String>[],
    };
    try {
      final service = ref.read(companyInformationServiceProvider);
      final results = await Future.wait([
        for (final resource in resources) service.request(_id, resource),
      ]);
      if (!mounted) return;
      for (var i = 0; i < resources.length; i++) {
        _data[resources[i]] = results[i];
      }
      if (hydrate && widget.tab == 2) {
        final profile = _object('company-profile');
        _controller('commercialName').text =
            profile['commercialName'] as String? ?? '';
        final contact = profile['contact'] as Map? ?? {};
        _controller('email').text = contact['email'] as String? ?? '';
        _controller('phone').text = contact['phone'] as String? ?? '';
        final activities = profile['economicActivities'] as List? ?? [];
        if (activities.isNotEmpty) {
          for (final activity in _activities) {
            activity.dispose();
          }
          _activities.clear();
          for (final item in activities) {
            _activities.add(
              _Activity(
                code: item['code'] as String,
                description: item['description'] as String,
                classificationTable: item['classificationTable'] as String?,
              ),
            );
          }
          _primary = activities.indexWhere((item) => item['isPrimary'] == true);
        }
      }
      if (hydrate && widget.tab == 5) {
        _groups.clear();
        for (final entry
            in (_object('workforce-distribution')['entries'] as List? ?? [])) {
          _groups.add(Map<String, dynamic>.from(entry as Map));
        }
        _groupsDirty = false;
      }
    } catch (error) {
      if (mounted) _readError = _message(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(
    String resource,
    Map<String, dynamic> body,
    String title, {
    bool replace = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final fingerprint = jsonEncode([_id, resource, body]);
    if (_pendingFingerprint != fingerprint) {
      _pendingFingerprint = fingerprint;
      _idempotencyKey = UsersService.newIdempotencyKey();
    }
    try {
      final result = await ref
          .read(companyInformationServiceProvider)
          .request(
            _id,
            resource,
            method: replace ? 'PUT' : 'POST',
            body: body,
            idempotencyKey: replace ? null : _idempotencyKey,
          );
      if (!mounted) return;
      _pendingFingerprint = null;
      _idempotencyKey = null;
      setState(() {
        if (replace) {
          _data[resource] = result;
        } else {
          _data[resource] = [
            ..._items(resource),
            result as Map<String, dynamic>,
          ];
        }
        if (resource == 'workforce-distribution') _groupsDirty = false;
        final clearFields = switch (resource) {
          'work-sites' => [
            'siteName',
            'typeDescription',
            'municipality',
            'department',
            'address',
          ],
          'processes' => [
            'processName',
            'processDescription',
            'mainActivities',
          ],
          'areas' => ['areaName', 'areaDescription'],
          'third-parties' => ['legalName', 'taxIdentifier', 'thirdDescription'],
          _ => <String>[],
        };
        for (final field in clearFields) {
          _controller(field).clear();
        }
        if (resource == 'areas') {
          _sets.remove('processIds');
          _sets.remove('workSiteIds');
        }
        if (resource == 'third-parties') _sets.remove('relationshipTypes');
      });
      await showDialog<void>(
        context: context,
        builder: (_) => OperationSuccessDialog(
          title: title,
          description: 'La información se guardó correctamente.',
          detail: widget.organization.legalName,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_readError != null) {
      return _Panel(
        title: 'No se pudo cargar la información',
        children: [
          Text(
            _readError!,
            style: const TextStyle(color: AppTheme.dashboardRed),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _Notice(_error!, error: true),
          ),
        AbsorbPointer(
          absorbing: _busy,
          child: switch (widget.tab) {
            2 => _profile(),
            3 => _sites(),
            4 => _structure(),
            5 => _workforce(),
            6 => _thirdParties(),
            7 => _findings(),
            8 => _people(),
            _ => const SizedBox.shrink(),
          },
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _input(
    String name,
    String label, {
    bool required = true,
    int max = 160,
    int lines = 1,
    String? hint,
    bool email = false,
    bool number = false,
    String? Function(String)? validate,
  }) => TextFormField(
    key: Key('company_$name'),
    controller: _controller(name),
    enabled: !_busy,
    maxLines: lines,
    maxLength: max,
    keyboardType: number
        ? TextInputType.number
        : email
        ? TextInputType.emailAddress
        : TextInputType.text,
    inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return required ? 'Completa este campo.' : null;
      if (email) return AccountFormValidators.email(text);
      if (number && (int.tryParse(text) ?? 0) < 1) {
        return 'Ingresa una cantidad mayor a cero.';
      }
      return validate?.call(text);
    },
    style: const TextStyle(color: AppTheme.dashboardBlueDark, fontSize: 14),
    decoration: _decoration(label, hint: hint),
  );

  Widget _button(
    String label,
    VoidCallback action, {
    IconData icon = Icons.save_outlined,
  }) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: _busy ? null : action,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.dashboardBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _profile() => Form(
    key: _form('profile'),
    child: _Panel(
      eyebrow: 'DATOS GENERALES',
      title: 'Información general de la empresa',
      children: [
        _Notice(
          _object('company-profile')['status'] == 'DRAFT'
              ? 'Borrador guardado'
              : 'Sin datos guardados',
        ),
        const SizedBox(height: 18),
        const Text(
          'La actividad económica es declarada por la organización. Registra el código y la descripción que correspondan a tu empresa.',
          style: TextStyle(color: AppTheme.dashboardMuted, height: 1.5),
        ),
        const SizedBox(height: 22),
        _input(
          'commercialName',
          'Nombre comercial (opcional)',
          required: false,
          max: 200,
        ),
        const SizedBox(height: 20),
        _heading('Actividad(es) económica(s) declarada(s)'),
        const Text(
          'Marca exactamente una actividad como principal.',
          style: TextStyle(color: AppTheme.dashboardMuted),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _activities.length; i++) _activityRow(i),
        OutlinedButton.icon(
          onPressed: () => setState(() => _activities.add(_Activity())),
          icon: const Icon(Icons.add),
          label: const Text('Agregar actividad'),
        ),
        const SizedBox(height: 22),
        _grid([
          _input(
            'email',
            'Correo institucional',
            email: true,
            required: false,
            max: 254,
          ),
          _input(
            'phone',
            'Teléfono institucional',
            max: 30,
            required: false,
            validate: (value) => RegExp(r'^[+0-9() .-]{7,30}$').hasMatch(value)
                ? null
                : 'Ingresa un teléfono válido.',
          ),
        ]),
        const SizedBox(height: 24),
        _button('Guardar datos generales', () {
          if (!_form('profile').currentState!.validate()) return;
          if (_primary < 0 || _primary >= _activities.length) {
            setState(() => _error = 'Selecciona una actividad principal.');
            return;
          }
          if (_activities
                  .map((a) => a.code.text.trim().toUpperCase())
                  .toSet()
                  .length !=
              _activities.length) {
            setState(
              () => _error = 'No repitas el código de una actividad económica.',
            );
            return;
          }
          _save(
            'company-profile',
            {
              'commercialName': _value('commercialName').isEmpty
                  ? null
                  : _value('commercialName'),
              'economicActivities': [
                for (var i = 0; i < _activities.length; i++)
                  {
                    'code': _activities[i].code.text.trim(),
                    'description': _activities[i].description.text.trim(),
                    'isPrimary': i == _primary,
                    if (_activities[i].classificationTable != null)
                      'classificationTable': _activities[i].classificationTable,
                  },
              ],
              'contact': {
                'email': _value('email').isEmpty ? null : _value('email'),
                'phone': _value('phone').isEmpty ? null : _value('phone'),
              },
              if (_object('company-profile')['version'] is int)
                'expectedVersion': _object('company-profile')['version'],
            },
            '¡Datos generales guardados!',
            replace: true,
          );
        }),
      ],
    ),
  );

  Widget _activityRow(int index) {
    final activity = _activities[index];
    return Container(
      key: ObjectKey(activity),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.dashboardBackground.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dashboardLine),
      ),
      child: Column(
        children: [
          _grid([
            TextFormField(
              key: Key('company_activity_code_$index'),
              controller: activity.code,
              maxLength: 12,
              decoration: _decoration('Código declarado'),
              validator: (value) =>
                  RegExp(r'^[A-Za-z0-9.-]{2,12}$').hasMatch(value?.trim() ?? '')
                  ? null
                  : 'Usa de 2 a 12 letras, números, puntos o guiones.',
            ),
            TextFormField(
              key: Key('company_activity_description_$index'),
              controller: activity.description,
              maxLength: 500,
              decoration: _decoration('Descripción'),
              validator: (value) => value?.trim().isNotEmpty == true
                  ? null
                  : 'Describe la actividad.',
            ),
          ]),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => setState(() => _primary = index),
                  icon: Icon(
                    _primary == index
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  label: const Text('Principal'),
                ),
              ),
              TextButton.icon(
                onPressed: _activities.length == 1
                    ? null
                    : () => setState(() {
                        final removed = _activities.removeAt(index);
                        // Dispose after the removed text fields leave the tree.
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => removed.dispose(),
                        );
                        if (_primary == index) {
                          _primary = 0;
                        } else if (_primary > index) {
                          _primary--;
                        }
                      }),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.dashboardRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sites() => Form(
    key: _form('sites'),
    child: _Panel(
      eyebrow: 'SEDES Y CENTROS DE TRABAJO',
      title: 'Lugares donde trabaja la organización',
      children: [
        _grid([
          _input('siteName', 'Nombre de la sede'),
          _choice('siteType', 'Tipo', const [
            SearchChoice('HEADQUARTERS', 'Sede principal'),
            SearchChoice('BRANCH', 'Sucursal'),
            SearchChoice('WORK_CENTER', 'Centro de trabajo'),
            SearchChoice('OTHER', 'Otro'),
          ], defaultValue: 'HEADQUARTERS'),
          _input(
            'typeDescription',
            'Describe el tipo',
            required: _choices['siteType'] == 'OTHER',
            max: 120,
          ),
          _input('municipality', 'Municipio', max: 120),
          _input(
            'department',
            'Departamento (opcional)',
            required: false,
            max: 120,
          ),
          _input('address', 'Dirección', max: 240),
        ]),
        const SizedBox(height: 24),
        _button('Registrar sede', () {
          if (!_form('sites').currentState!.validate()) return;
          _save('work-sites', {
            'name': _value('siteName'),
            'type': _choices['siteType'] ?? 'HEADQUARTERS',
            if (_value('typeDescription').isNotEmpty)
              'typeDescription': _value('typeDescription'),
            'municipality': _value('municipality'),
            if (_value('department').isNotEmpty)
              'department': _value('department'),
            'address': _value('address'),
          }, '¡Sede registrada!');
        }),
        const SizedBox(height: 24),
        _records(
          'Sedes registradas',
          _items('work-sites'),
          subtitle: (item) => '${item['municipality']} · ${item['address']}',
        ),
      ],
    ),
  );

  Widget _structure() => Column(
    children: [
      Form(
        key: _form('process'),
        child: _Panel(
          eyebrow: 'PROCESOS Y ÁREAS',
          title: 'Cómo está organizada la empresa',
          children: [
            _heading('Agregar un proceso'),
            _grid([
              _input('processName', 'Nombre'),
              _input(
                'mainActivities',
                'Actividades principales, separadas por coma',
                required: false,
                max: 6000,
                hint: 'Compras, producción',
                validate: (value) {
                  final parts = value
                      .split(',')
                      .map((v) => v.trim())
                      .where((v) => v.isNotEmpty)
                      .toList();
                  return parts.length > 30 || parts.any((v) => v.length > 200)
                      ? 'Máximo 30 actividades de hasta 200 caracteres.'
                      : null;
                },
              ),
            ]),
            const SizedBox(height: 18),
            _input(
              'processDescription',
              'Descripción (opcional)',
              required: false,
              max: 1000,
              lines: 3,
            ),
            const SizedBox(height: 24),
            _button('Crear proceso', () {
              if (!_form('process').currentState!.validate()) return;
              _save('processes', {
                'name': _value('processName'),
                'description': _value('processDescription'),
                'mainActivities': _value('mainActivities')
                    .split(',')
                    .map((v) => v.trim())
                    .where((v) => v.isNotEmpty)
                    .toList(),
              }, '¡Proceso creado!');
            }),
            const SizedBox(height: 24),
            _records('Procesos', _items('processes')),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Form(
        key: _form('area'),
        child: _Panel(
          title: 'Agregar un área',
          children: [
            _input('areaName', 'Nombre'),
            const SizedBox(height: 18),
            _input(
              'areaDescription',
              'Descripción (opcional)',
              required: false,
              max: 1000,
              lines: 3,
            ),
            const SizedBox(height: 18),
            _grid([
              _multi(
                'processIds',
                'Procesos relacionados',
                _active('processes'),
              ),
              _multi(
                'workSiteIds',
                'Sedes relacionadas',
                _active('work-sites'),
              ),
            ]),
            const SizedBox(height: 24),
            _button('Crear área', () {
              if (!_form('area').currentState!.validate()) return;
              _save('areas', {
                'name': _value('areaName'),
                'description': _value('areaDescription'),
                'processIds': (_sets['processIds'] ?? {}).toList(),
                'workSiteIds': (_sets['workSiteIds'] ?? {}).toList(),
              }, '¡Área creada!');
            }),
            const SizedBox(height: 24),
            _records('Áreas', _items('areas')),
          ],
        ),
      ),
    ],
  );

  Widget _workforce() => Form(
    key: _form('workers'),
    child: _Panel(
      eyebrow: 'CARACTERIZAR TRABAJADORES',
      title: 'Registrar grupos, no expedientes individuales',
      children: [
        const _Notice(
          'Cada grupo guarda una cantidad de personas con características compartidas. No ingreses nombres, documentos, datos de salud ni correos individuales.',
        ),
        const SizedBox(height: 22),
        _grid([
          _choice('workerSite', 'Sede (opcional)', [
            const SearchChoice('', 'Sin especificar'),
            ..._resourceChoices('work-sites'),
          ], defaultValue: ''),
          _choice('workerArea', 'Área (opcional)', [
            const SearchChoice('', 'Sin especificar'),
            ..._resourceChoices('areas'),
          ], defaultValue: ''),
          _input(
            'relationshipType',
            'Tipo de vinculación',
            max: 120,
            hint: 'Directa, temporal…',
          ),
          _input('jobTitle', 'Cargo o grupo de cargos'),
          _input('shift', 'Turno', max: 100, hint: 'Diurno, nocturno…'),
          _input(
            'workSchedule',
            'Jornada',
            max: 120,
            hint: 'Completa, parcial…',
          ),
          _input('workerCount', 'Cantidad de personas', number: true, max: 9),
        ]),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            if (!_form('workers').currentState!.validate()) return;
            if (_groups.length >= 500) {
              setState(() => _error = 'Se permiten hasta 500 grupos.');
              return;
            }
            setState(() {
              _groups.add({
                if ((_choices['workerSite'] ?? '').isNotEmpty)
                  'workSiteId': _choices['workerSite'],
                if ((_choices['workerArea'] ?? '').isNotEmpty)
                  'areaId': _choices['workerArea'],
                for (final field in [
                  'relationshipType',
                  'jobTitle',
                  'shift',
                  'workSchedule',
                ])
                  field: _value(field),
                'workerCount': int.parse(_value('workerCount')),
              });
              _groupsDirty = true;
            });
          },
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Agregar grupo'),
        ),
        const SizedBox(height: 22),
        _heading('Grupos de esta organización'),
        if (_groups.isEmpty)
          const _Notice(
            'Aún no hay grupos. Agrega uno y luego guarda los cambios.',
          ),
        for (var i = 0; i < _groups.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${_groups[i]['jobTitle']} · ${_groups[i]['workerCount']} personas',
            ),
            subtitle: Text(
              '${_groups[i]['relationshipType']} · ${_groups[i]['shift']} · ${_groups[i]['workSchedule']}',
            ),
            trailing: IconButton(
              tooltip: 'Quitar grupo',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() {
                _groups.removeAt(i);
                _groupsDirty = true;
              }),
            ),
          ),
        if (_groupsDirty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Tienes cambios sin guardar.',
              style: TextStyle(color: AppTheme.dashboardOrange),
            ),
          ),
        const SizedBox(height: 24),
        _button(
          'Guardar caracterización',
          () => _save(
            'workforce-distribution',
            {
              'entries': _groups,
              if (_object('workforce-distribution')['version'] is int)
                'expectedVersion': _object('workforce-distribution')['version'],
            },
            '¡Caracterización guardada!',
            replace: true,
          ),
        ),
      ],
    ),
  );

  Widget _thirdParties() => Form(
    key: _form('thirdParty'),
    child: _Panel(
      eyebrow: 'CONTRATISTAS Y PROVEEDORES',
      title: 'Empresas externas relacionadas',
      children: [
        const _Notice(
          'Registra empresas u organizaciones. No incluyas personas naturales, contactos personales ni trabajadores de terceros.',
        ),
        const SizedBox(height: 22),
        _grid([
          _input('legalName', 'Razón social', max: 200),
          _input(
            'taxIdentifier',
            'Identificación tributaria',
            max: 32,
            validate: (value) =>
                value.length < 3 ? 'Ingresa al menos 3 caracteres.' : null,
          ),
        ]),
        const SizedBox(height: 18),
        _heading('Tipo de relación'),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final entry in {
              'CONTRACTOR': 'Contratista',
              'SUPPLIER': 'Proveedor',
            }.entries)
              FilterChip(
                label: Text(entry.value),
                selected:
                    _sets['relationshipTypes']?.contains(entry.key) == true,
                onSelected: (selected) => setState(() {
                  final values = _sets.putIfAbsent(
                    'relationshipTypes',
                    () => {},
                  );
                  selected ? values.add(entry.key) : values.remove(entry.key);
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Puedes seleccionar uno o ambos.',
          style: TextStyle(color: AppTheme.dashboardMuted),
        ),
        const SizedBox(height: 18),
        _input(
          'thirdDescription',
          'Qué realiza o suministra',
          max: 1000,
          lines: 3,
        ),
        const SizedBox(height: 24),
        _button('Registrar empresa', () {
          if (!_form('thirdParty').currentState!.validate()) return;
          if (_sets['relationshipTypes']?.isNotEmpty != true) {
            setState(() => _error = 'Selecciona al menos un tipo de relación.');
            return;
          }
          _save('third-parties', {
            'legalName': _value('legalName'),
            'taxIdentifier': _value('taxIdentifier'),
            'relationshipTypes': _sets['relationshipTypes']!.toList(),
            'description': _value('thirdDescription'),
          }, '¡Empresa externa registrada!');
        }),
        const SizedBox(height: 24),
        _records(
          'Empresas relacionadas',
          _items('third-parties'),
          title: (item) => item['legalName'] as String,
          subtitle: (item) =>
              '${item['taxIdentifier']} · ${(item['relationshipTypes'] as List).map((v) => v == 'CONTRACTOR' ? 'Contratista' : 'Proveedor').join(', ')}',
        ),
      ],
    ),
  );

  Widget _findings() => _Panel(
    eyebrow: 'COMPROBACIÓN AUTOMÁTICA',
    title: 'Comprobar datos registrados',
    children: [
      const Text(
        'Consulta los datos registrados y los aspectos que conviene revisar.',
        style: TextStyle(color: AppTheme.dashboardMuted, height: 1.5),
      ),
      const SizedBox(height: 18),
      const _Notice(
        'Esta comprobación no es una aprobación ni indica cumplimiento legal. No modifica la información.',
      ),
      const SizedBox(height: 22),
      _button('Consultar hallazgos actuales', () async {
        setState(() {
          _busy = true;
          _error = null;
        });
        try {
          final result = await ref
              .read(companyInformationServiceProvider)
              .request(_id, 'information-findings');
          if (mounted) setState(() => _data['information-findings'] = result);
        } catch (error) {
          if (mounted) setState(() => _error = _message(error));
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      }, icon: Icons.fact_check_outlined),
      if (_data.containsKey('information-findings')) ...[
        const SizedBox(height: 24),
        for (final item
            in (_object('information-findings')['findings'] as List? ?? []))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.info_outline,
              color: AppTheme.dashboardBlue,
            ),
            title: Text(item['message'] as String),
            subtitle: Text(item['section'] as String),
          ),
        if ((_object('information-findings')['findings'] as List? ?? [])
            .isEmpty)
          const _Notice(
            'La consulta no devolvió hallazgos. Esto no representa una aprobación de la ficha.',
          ),
      ],
    ],
  );

  Widget _people() {
    final roles = ref.watch(organizationRolesProvider);
    return Form(
      key: _form('people'),
      child: _Panel(
        title: 'Vincular a alguien que ya tiene cuenta',
        eyebrow: 'PERSONAS Y ROLES',
        children: [
          const Text(
            'Escribe el correo con el que esa persona inicia sesión. El rol se habilita al confirmar la vinculación; conserva su contraseña actual.',
            style: TextStyle(color: AppTheme.dashboardMuted, height: 1.5),
          ),
          const SizedBox(height: 22),
          _input('memberEmail', 'Correo de la cuenta', email: true, max: 254),
          const SizedBox(height: 18),
          roles.when(
            data: (items) => _choice('memberRole', 'Rol en esta empresa', [
              for (final role in items)
                SearchChoice(role.code, role.label, role.code),
            ]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Column(
              children: [
                Text(_message(error)),
                TextButton(
                  onPressed: () => ref.invalidate(organizationRolesProvider),
                  child: const Text('Reintentar roles'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Alcance: toda la empresa',
            style: TextStyle(color: AppTheme.dashboardMuted),
          ),
          const SizedBox(height: 24),
          _button('Vincular y habilitar acceso', () async {
            if (!_form('people').currentState!.validate()) return;
            final role = _choices['memberRole'];
            if (role == null ||
                roles.asData?.value.any((item) => item.code == role) != true) {
              setState(() => _error = 'Selecciona un rol disponible.');
              return;
            }
            final body = jsonEncode([_id, _value('memberEmail'), role]);
            if (_pendingFingerprint != body) {
              _pendingFingerprint = body;
              _idempotencyKey = UsersService.newIdempotencyKey();
            }
            setState(() {
              _busy = true;
              _error = null;
            });
            try {
              await ref
                  .read(membershipsServiceProvider)
                  .link(
                    organizationId: _id,
                    email: _value('memberEmail'),
                    role: role,
                    scope: const MembershipScope('ORGANIZATION'),
                    idempotencyKey: _idempotencyKey!,
                  );
              if (!mounted) return;
              _pendingFingerprint = null;
              await showDialog<void>(
                context: context,
                builder: (_) => OperationSuccessDialog(
                  title: '¡Acceso habilitado!',
                  description: 'La cuenta quedó vinculada a la empresa.',
                  detail: _value('memberEmail'),
                ),
              );
              if (mounted) await _load(hydrate: false);
            } catch (error) {
              if (mounted) setState(() => _error = _message(error));
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          }, icon: Icons.person_add_alt_1_outlined),
          const SizedBox(height: 24),
          _records(
            'Personas vinculadas',
            _items('memberships'),
            title: (item) => item['email'] as String? ?? 'Cuenta vinculada',
            subtitle: (item) =>
                OrganizationRole(item['role'] as String? ?? '').label,
          ),
        ],
      ),
    );
  }

  List<SearchChoice> _resourceChoices(String resource) => [
    for (final item in _active(resource))
      SearchChoice(item['id'] as String, item['name'] as String),
  ];

  Widget _choice(
    String name,
    String label,
    List<SearchChoice> options, {
    String? defaultValue,
  }) => SearchableChoiceField(
    fieldKey: 'company_$name',
    label: label,
    value: _choices[name] ?? defaultValue,
    enabled: !_busy,
    options: options,
    onSelected: (value) => setState(() => _choices[name] = value),
  );

  Widget _multi(
    String name,
    String label,
    List<Map<String, dynamic>> options,
  ) => _MultiReferenceField(
    key: ValueKey(name),
    label: label,
    options: options,
    selected: _sets[name] ?? {},
    onChanged: (selected) => setState(() => _sets[name] = selected),
  );

  Widget _records(
    String heading,
    List<Map<String, dynamic>> items, {
    String Function(Map<String, dynamic>)? subtitle,
    String Function(Map<String, dynamic>)? title,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading('$heading (${items.length})'),
      if (items.isEmpty) const _Notice('Aún no hay registros en esta sección.'),
      for (final item in items)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dashboardLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.check_circle_outline,
              color: AppTheme.dashboardBlue,
            ),
            title: Text(
              title?.call(item) ?? item['name'] as String? ?? 'Registro',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.dashboardBlueDark,
              ),
            ),
            subtitle: subtitle == null ? null : Text(subtitle(item)),
          ),
        ),
    ],
  );
}

class _Activity {
  _Activity({
    String code = '',
    String description = '',
    this.classificationTable,
  }) : code = TextEditingController(text: code),
       description = TextEditingController(text: description);
  final TextEditingController code;
  final TextEditingController description;
  final String? classificationTable;
  void dispose() {
    code.dispose();
    description.dispose();
  }
}

InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
  labelText: label,
  hintText: hint,
  counterText: '',
  alignLabelWithHint: true,
  filled: true,
  fillColor: AppTheme.dashboardBackground.withValues(alpha: .4),
  labelStyle: const TextStyle(
    color: AppTheme.dashboardMuted,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  ),
  floatingLabelStyle: const TextStyle(
    color: AppTheme.dashboardBlue,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppTheme.dashboardLine),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppTheme.dashboardBlue, width: 1.6),
  ),
);

Widget _heading(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppTheme.dashboardBlueDark,
    ),
  ),
);

Widget _grid(List<Widget> children) => LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth >= 600
        ? (constraints.maxWidth - 18) / 2
        : constraints.maxWidth;
    return Wrap(
      spacing: 18,
      runSpacing: 20,
      children: [
        for (final child in children) SizedBox(width: width, child: child),
      ],
    );
  },
);

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children, this.eyebrow});
  final String title;
  final String? eyebrow;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: AppTheme.dashboardBlue,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppTheme.dashboardBlueDark,
            ),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: (error ? AppTheme.dashboardRed : AppTheme.dashboardBlue)
          .withValues(alpha: .07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.dashboardLine),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: error ? AppTheme.dashboardRed : AppTheme.dashboardBlueDark,
        height: 1.5,
      ),
    ),
  );
}

class _MultiReferenceField extends StatefulWidget {
  const _MultiReferenceField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final String label;
  final List<Map<String, dynamic>> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  @override
  State<_MultiReferenceField> createState() => _MultiReferenceFieldState();
}

class _MultiReferenceFieldState extends State<_MultiReferenceField> {
  String _query = '';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(widget.label),
      TextField(
        decoration: _decoration('Buscar…'),
        onChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
      ),
      const SizedBox(height: 8),
      Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dashboardLine),
        ),
        child: widget.options.isEmpty
            ? const Center(child: Text('Aún no hay registros activos.'))
            : ListView(
                primary: false,
                children: [
                  for (final item in widget.options.where(
                    (item) =>
                        (item['name'] as String).toLowerCase().contains(_query),
                  ))
                    CheckboxListTile(
                      dense: true,
                      title: Text(item['name'] as String),
                      value: widget.selected.contains(item['id']),
                      onChanged: (value) {
                        final selected = {...widget.selected};
                        value == true
                            ? selected.add(item['id'] as String)
                            : selected.remove(item['id']);
                        widget.onChanged(selected);
                      },
                    ),
                ],
              ),
      ),
    ],
  );
}
