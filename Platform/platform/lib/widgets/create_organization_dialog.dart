import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../models/api_failure.dart';
import '../models/organization.dart';
import '../models/user_account.dart';
import '../providers/users_providers.dart';

typedef CreateOrganization =
    Future<Organization> Function({
      required String legalId,
      required String legalName,
      required String administratorId,
    });

class CreateOrganizationDialog extends ConsumerStatefulWidget {
  const CreateOrganizationDialog({
    super.key,
    required this.onCreateOrganization,
    this.existingLegalIds = const [],
  });

  final CreateOrganization onCreateOrganization;
  final List<String> existingLegalIds;

  @override
  ConsumerState<CreateOrganizationDialog> createState() =>
      _CreateOrganizationDialogState();
}

class _CreateOrganizationDialogState
    extends ConsumerState<CreateOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _legalId = TextEditingController();
  final _legalName = TextEditingController();
  final _administratorSearch = TextEditingController();
  UserAccount? _administrator;
  bool _isSubmitting = false;
  String? _administratorError;
  String? _error;

  @override
  void dispose() {
    _legalId.dispose();
    _legalName.dispose();
    _administratorSearch.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final administrator = _administrator;
    if (administrator == null || administrator.status != 'ACTIVE') {
      setState(
        () => _administratorError =
            'Selecciona una cuenta existente y activa como administradora.',
      );
      return;
    }
    setState(() {
      _administratorError = null;
      _isSubmitting = true;
    });
    try {
      final created = await widget.onCreateOrganization(
        legalId: _legalId.text.trim(),
        legalName: _legalName.text.trim(),
        administratorId: administrator.id,
      );
      if (mounted) Navigator.pop(context, created);
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.supportMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo confirmar el registro. Revisa la conexión e intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validateLegalId(String? value) {
    final legalId = value?.trim() ?? '';
    if (legalId.isEmpty) return 'Ingresa la identificación legal.';
    if (legalId.length > 64) {
      return 'La identificación legal no debe superar 64 caracteres.';
    }
    if (widget.existingLegalIds.any(
      (existing) => existing.trim().toLowerCase() == legalId.toLowerCase(),
    )) {
      return 'Ya existe una empresa con esta identificación legal.';
    }
    return null;
  }

  String? _validateLegalName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Ingresa la razón social.';
    if (name.length > 200) return 'Máximo 200 caracteres.';
    return null;
  }

  InputDecoration _decoration(
    String label, {
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppTheme.dashboardMuted, fontSize: 13),
    errorMaxLines: 2,
    filled: true,
    fillColor: AppTheme.dashboardBackground.withValues(alpha: .35),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.dashboardLine),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.dashboardBlue, width: 1.5),
    ),
    suffixIcon: suffix,
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSubmitting,
    child: AlertDialog(
      key: const Key('create_organization_dialog'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.all(16),
      scrollable: true,
      title: Row(
        children: [
          const Icon(
            Icons.add_business_outlined,
            color: AppTheme.dashboardBlue,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Registrar empresa',
              style: TextStyle(
                color: AppTheme.dashboardBlueDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar formulario',
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.dashboardMuted),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ingresa los datos legales y asigna una cuenta activa como administradora inicial.',
                style: TextStyle(
                  color: AppTheme.dashboardMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('organization_legal_id'),
                controller: _legalId,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                maxLength: 64,
                style: const TextStyle(color: AppTheme.dashboardBlueDark),
                decoration: _decoration('Identificación legal / NIT'),
                validator: _validateLegalId,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('organization_legal_name'),
                controller: _legalName,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                style: const TextStyle(color: AppTheme.dashboardBlueDark),
                decoration: _decoration('Razón social'),
                validator: _validateLegalName,
              ),
              const SizedBox(height: 6),
              const Text(
                'Cuenta administradora inicial',
                style: TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('organization_admin_search'),
                controller: _administratorSearch,
                onChanged: (_) => setState(() {
                  _administrator = null;
                  _administratorError = null;
                }),
                style: const TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 13,
                ),
                decoration: _decoration(
                  'Buscar cuenta por correo o rol',
                  suffix: const Icon(
                    Icons.search,
                    color: AppTheme.dashboardMuted,
                  ),
                ),
              ),
              if (_administratorError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _administratorError!,
                  key: const Key('organization_admin_error'),
                  style: const TextStyle(
                    color: AppTheme.dashboardRed,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _administratorOptions(ref.watch(userAccountsProvider)),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  key: const Key('create_organization_error'),
                  style: const TextStyle(
                    color: AppTheme.dashboardRed,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dashboardBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('organization_submit'),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_business_outlined, size: 18),
                label: Text(_isSubmitting ? 'Registrando…' : 'Registrar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dashboardBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _administratorOptions(
    AsyncValue<List<UserAccount>> accounts,
  ) => accounts.when(
    loading: () => const SizedBox(
      height: 72,
      child: Center(
        child: CircularProgressIndicator(color: AppTheme.dashboardBlue),
      ),
    ),
    error: (_, _) => SizedBox(
      height: 72,
      child: Center(
        child: TextButton.icon(
          onPressed: () => ref.invalidate(userAccountsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('No se pudieron cargar las cuentas. Reintentar'),
        ),
      ),
    ),
    data: (items) {
      final active = items.where((account) => account.status == 'ACTIVE');
      final query = _administratorSearch.text.trim().toLowerCase();
      final filtered = active
          .where(
            (account) =>
                query.isEmpty ||
                '${account.email} ${account.roles.join(' ')}'
                    .toLowerCase()
                    .contains(query),
          )
          .toList();
      if (filtered.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            active.isEmpty
                ? 'No hay cuentas activas para asignar.'
                : 'No hay cuentas que coincidan con la búsqueda.',
            key: const Key('organization_admin_empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.dashboardMuted,
              fontSize: 12,
            ),
          ),
        );
      }
      return Container(
        key: const Key('organization_admin_options'),
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.dashboardBackground.withValues(alpha: .35),
          border: Border.all(color: AppTheme.dashboardLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final account = filtered[index];
            final selected = account.id == _administrator?.id;
            return Material(
              color: Colors.transparent,
              child: ListTile(
                key: Key('organization_admin_${account.id}'),
                dense: true,
                selected: selected,
                selectedTileColor: AppTheme.dashboardBlue.withValues(
                  alpha: .08,
                ),
                leading: Icon(
                  selected ? Icons.check_circle : Icons.account_circle_outlined,
                  color: selected
                      ? AppTheme.dashboardGreen
                      : AppTheme.dashboardBlue,
                  size: 21,
                ),
                title: Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.dashboardBlueDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  account.roles.isEmpty
                      ? 'Sin roles'
                      : account.roles.join(', '),
                  style: const TextStyle(
                    color: AppTheme.dashboardMuted,
                    fontSize: 11,
                  ),
                ),
                onTap: () => setState(() {
                  _administrator = account;
                  _administratorError = null;
                  _administratorSearch.text = account.email;
                }),
              ),
            );
          },
        ),
      );
    },
  );
}
