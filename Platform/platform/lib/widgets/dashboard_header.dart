import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/auth_identity.dart';
import 'organization_selector.dart';

void _ignoreHeaderAction(String _) {}

/// Focused header for the company workspace: account access and navigation.
class DashboardCompanyHeader extends DashboardHeader {
  const DashboardCompanyHeader({
    super.key,
    required super.isWide,
    required super.identity,
    required super.onProfileAction,
    super.onOpenDrawer,
  }) : super(
         onSearchChanged: _ignoreHeaderAction,
         onNotificationSelected: _ignoreHeaderAction,
       );

  @override
  Widget build(BuildContext context) => !isWide
      ? _mobileBrand(context)
      : Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 18, 8),
          child: Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                color: AppTheme.dashboardBlue,
                size: 19,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Gestión SG-SST  /  Ficha empresarial',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.dashboardMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _profileMenu(context),
            ],
          ),
        );
}

/// Shared dashboard top bar with organization selector, global search,
/// notifications, and the signed-in profile menu.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.isWide,
    required this.identity,
    required this.onSearchChanged,
    required this.onNotificationSelected,
    required this.onProfileAction,
    this.onOpenDrawer,
    this.onCreateAccount,
    this.onCreateOrganization,
    this.searchHint,
  });

  final bool isWide;
  final AuthIdentity identity;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onNotificationSelected;
  final ValueChanged<String> onProfileAction;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onCreateOrganization;
  final String? searchHint;

  @override
  Widget build(BuildContext context) =>
      Column(children: [if (!isWide) _mobileBrand(context), _toolbar(context)]);

  Widget _mobileBrand(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.dashboardBlueDark),
          onPressed: onOpenDrawer,
        ),
        const Text(
          'SST',
          style: TextStyle(
            color: AppTheme.dashboardBlueDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'CRM',
          style: TextStyle(
            color: AppTheme.dashboardGreen,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _profileMenu(context),
      ],
    ),
  );

  Widget _toolbar(BuildContext context) =>
      onCreateAccount != null || onCreateOrganization != null
      ? _workspaceToolbar(context)
      : _homeToolbar(context);

  Widget _homeToolbar(BuildContext context) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        if (isWide) const SizedBox(width: 265, child: OrganizationSelector()),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 44,
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .88),
              border: Border.all(color: AppTheme.dashboardLine),
              borderRadius: BorderRadius.circular(13),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.dashboardBlueDark,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText:
                    searchHint ?? 'Buscar trabajadores, documentos, riesgos...',
                hintStyle: const TextStyle(
                  color: AppTheme.dashboardMuted,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.dashboardMuted,
                  size: 21,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _notificationMenu(),
        if (isWide) const SizedBox(width: 5),
        if (isWide) _profileMenu(context),
      ],
    ),
  );

  Widget _workspaceToolbar(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final isOrganization = onCreateOrganization != null;
      final button = SizedBox(
        height: 44,
        child: FilledButton.icon(
          key: Key(
            isOrganization ? 'create_organization_open' : 'create_account_open',
          ),
          onPressed: onCreateOrganization ?? onCreateAccount,
          icon: Icon(
            isOrganization
                ? Icons.add_business_outlined
                : Icons.person_add_alt_1,
            size: 18,
          ),
          label: Text(
            isOrganization ? 'Registrar empresa' : 'Crear nueva cuenta',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.dashboardBlue,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.dashboardLine),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: TextField(
                      key: Key(
                        isOrganization
                            ? 'organizations_search'
                            : 'accounts_search',
                      ),
                      onChanged: onSearchChanged,
                      style: const TextStyle(
                        color: AppTheme.dashboardBlueDark,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: searchHint,
                        hintStyle: const TextStyle(
                          color: AppTheme.dashboardMuted,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.dashboardMuted,
                          size: 21,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!compact) ...[const SizedBox(width: 8), button],
                if (isWide) ...[
                  const SizedBox(width: 5),
                  _profileMenu(context),
                ],
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: button),
            ],
          ],
        ),
      );
    },
  );

  Widget _notificationMenu() => PopupMenuButton<String>(
    tooltip: 'Notificaciones',
    onSelected: onNotificationSelected,
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'Tienes 3 acciones prioritarias para este mes.',
        child: Text('3 acciones pendientes'),
      ),
      PopupMenuItem(
        value:
            'La inspección de extintores está programada para el 18 de abril.',
        child: Text('Inspección programada'),
      ),
      PopupMenuItem(
        value: 'La matriz de peligros fue actualizada hace 4 horas.',
        child: Text('Documento actualizado'),
      ),
    ],
    child: Stack(
      children: [
        const Padding(
          padding: EdgeInsets.all(11),
          child: Icon(
            Icons.notifications_none,
            color: AppTheme.dashboardMuted,
            size: 23,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.dashboardRed,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _profileMenu(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Cuenta autenticada',
    onSelected: onProfileAction,
    itemBuilder: (context) => const [
      PopupMenuItem(value: 'Perfil', child: Text('Mi perfil')),
      PopupMenuItem(value: 'Configuración', child: Text('Configuración')),
      PopupMenuDivider(),
      PopupMenuItem(value: 'Salir', child: Text('Salir')),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        children: [
          const CircleAvatar(radius: 19, child: Icon(Icons.person_outline)),
          const SizedBox(width: 8),
          if (MediaQuery.sizeOf(context).width >= 850)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    identity.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.dashboardBlueDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Cuenta autenticada',
                    style: TextStyle(
                      color: AppTheme.dashboardMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.dashboardBlueDark,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
