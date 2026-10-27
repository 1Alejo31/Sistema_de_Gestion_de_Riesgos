import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../models/api_failure.dart';
import '../models/user_account.dart';
import '../providers/memberships_providers.dart';
import '../providers/organizations_providers.dart';
import '../services/users_service.dart';
import 'searchable_choice_field.dart';

class LinkAccountDialog extends ConsumerStatefulWidget {
  const LinkAccountDialog({super.key, required this.account});
  final UserAccount account;
  @override
  ConsumerState<LinkAccountDialog> createState() => _LinkAccountDialogState();
}

class _LinkAccountDialogState extends ConsumerState<LinkAccountDialog> {
  String? _organizationId;
  String? _role;
  String? _scope;
  String? _error;
  String? _pendingBody;
  String? _idempotencyKey;
  bool _busy = false;
  bool _validate = false;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _validate = true;
      _error = null;
    });
    final id = _organizationId;
    final role = _role;
    if (id == null || role == null || _scope == null) return;
    final organizations = ref.read(organizationsProvider).asData?.value;
    final roles = ref.read(organizationRolesProvider).asData?.value;
    final scopes = ref.read(membershipScopesProvider(id)).asData?.value;
    final scope = scopes?.where((item) => item.key == _scope).firstOrNull;
    if (organizations?.any((item) => item.id == id) != true ||
        roles?.any((item) => item.code == role) != true ||
        scope == null) {
      return;
    }
    final body = jsonEncode([id, widget.account.email, role, scope.toJson()]);
    if (_pendingBody != body) {
      _pendingBody = body;
      _idempotencyKey = UsersService.newIdempotencyKey();
    }
    setState(() => _busy = true);
    try {
      final linked = await ref
          .read(membershipsServiceProvider)
          .link(
            organizationId: id,
            email: widget.account.email,
            role: role,
            scope: scope,
            idempotencyKey: _idempotencyKey!,
          );
      if (mounted) {
        ref.invalidate(membershipScopesProvider(id));
        Navigator.pop(context, linked);
      }
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.supportMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo confirmar la vinculación. Puedes reintentar con los mismos datos.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _options<T>(
    AsyncValue<List<T>> data,
    VoidCallback retry,
    Widget Function(List<T>) builder,
  ) => data.when(
    skipLoadingOnRefresh: false,
    loading: () => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (error, stack) => Column(
      children: [
        Text(
          error is ApiFailure
              ? error.supportMessage
              : 'No se pudieron cargar las opciones.',
          style: const TextStyle(color: AppTheme.dashboardRed),
        ),
        TextButton.icon(
          onPressed: _busy ? null : retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    ),
    data: builder,
  );

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);
    final id = _organizationId;
    final roles = id == null ? null : ref.watch(organizationRolesProvider);
    final scopes = id == null ? null : ref.watch(membershipScopesProvider(id));
    final available =
        widget.account.status == 'ACTIVE' &&
        !widget.account.roles.contains('SUPER_ADMIN');
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        key: const Key('link_account_dialog'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Personas y roles dentro de una empresa',
                style: TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar vinculación',
              onPressed: _busy ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppTheme.dashboardMuted),
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.account.email,
                key: const Key('link_account_email'),
                style: const TextStyle(
                  color: AppTheme.dashboardBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              if (!available) ...[
                Text(
                  widget.account.roles.contains('SUPER_ADMIN')
                      ? 'Una cuenta de superadministrador no puede vincularse a una empresa.'
                      : 'La cuenta debe estar activa para vincularla a una empresa.',
                  style: const TextStyle(color: AppTheme.dashboardRed),
                ),
                const SizedBox(height: 16),
              ],
              _options(
                organizations,
                () => ref.invalidate(organizationsProvider),
                (items) => items.isEmpty
                    ? Column(
                        children: [
                          const Text(
                            'El servicio no devolvió empresas disponibles. Actualiza el listado para volver a consultar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.dashboardMuted),
                          ),
                          TextButton.icon(
                            key: const Key('link_organizations_reload'),
                            onPressed: _busy
                                ? null
                                : () => ref.invalidate(organizationsProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar empresas'),
                          ),
                        ],
                      )
                    : SearchableChoiceField(
                        fieldKey: 'link_organization',
                        label: 'Empresa',
                        enabled: !_busy && available,
                        value: id,
                        error: _validate && id == null
                            ? 'Selecciona una empresa.'
                            : null,
                        options: [
                          for (final item in items)
                            SearchChoice(item.id, item.legalName, item.legalId),
                        ],
                        onSelected: (value) => setState(() {
                          _organizationId = value;
                          _role = null;
                          _scope = null;
                          _error = null;
                          _validate = false;
                        }),
                      ),
              ),
              const SizedBox(height: 12),
              const Text(
                'El rol de una persona puede ser distinto en cada empresa. '
                'El alcance indica si participa en toda la empresa o en una sede o proceso.',
                style: TextStyle(color: AppTheme.dashboardMuted, height: 1.5),
              ),
              if (roles != null && scopes != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Vincular una cuenta existente',
                  style: TextStyle(
                    color: AppTheme.dashboardBlueDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El acceso se activa al confirmar la vinculación. '
                  'La persona conserva su contraseña actual.',
                  style: TextStyle(color: AppTheme.dashboardMuted, height: 1.5),
                ),
                const SizedBox(height: 20),
                _options(
                  roles,
                  () => ref.invalidate(organizationRolesProvider),
                  (items) => SearchableChoiceField(
                    fieldKey: 'link_role',
                    label: 'Rol en esta empresa',
                    value: _role,
                    enabled: !_busy && available,
                    error: _validate && _role == null
                        ? 'Selecciona un rol.'
                        : null,
                    options: [
                      for (final item in items)
                        SearchChoice(item.code, item.label, item.code),
                    ],
                    onSelected: (value) => setState(() {
                      _role = value;
                      _error = null;
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                _options(
                  scopes,
                  () => ref.invalidate(membershipScopesProvider(id!)),
                  (items) => SearchableChoiceField(
                    fieldKey: 'link_scope',
                    label: 'Alcance',
                    value: _scope,
                    enabled: !_busy && available,
                    error: _validate && _scope == null
                        ? 'Selecciona un alcance.'
                        : null,
                    options: [
                      for (final item in items)
                        SearchChoice(item.key, item.label),
                    ],
                    onSelected: (value) => setState(() {
                      _scope = value;
                      _error = null;
                    }),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  key: const Key('link_account_error'),
                  style: const TextStyle(color: AppTheme.dashboardRed),
                ),
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('link_account_submit'),
              onPressed:
                  _busy ||
                      !available ||
                      (id != null &&
                          (roles?.asData == null || scopes?.asData == null))
                  ? null
                  : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link),
              label: Text(
                _busy ? 'Vinculando…' : 'Vincular y habilitar acceso',
              ),
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
    );
  }
}
