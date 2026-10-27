import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../config/app_theme.dart';
import 'dashboard_widgets.dart';
import 'organization_selector.dart';

const _organizationExpandedSuffix = '|organization-expanded';

const dashboardManagementModules = [
  '1. Información general de la empresa',
  '2. Evaluación inicial',
  '3. Política SST',
  '4. Objetivos SST',
  '5. Requisitos legales',
  '6. Identificación de peligros',
  '7. Valoración de riesgos',
  '8. Programas de gestión',
  '9. Recursos',
  '10. Indicadores',
  '11. Plan anual de trabajo',
];

String dashboardPageLabel(String page) =>
    page.endsWith(_organizationExpandedSuffix)
    ? page.substring(0, page.length - _organizationExpandedSuffix.length)
    : page;

String dashboardPageSelection(
  String page, {
  required bool organizationExpanded,
}) => organizationExpanded ? '$page$_organizationExpandedSuffix' : page;

/// Reusable navigation rail for dashboard pages.
/// Page-specific navigation and dialogs are supplied through callbacks.
class DashboardSidebar extends ConsumerStatefulWidget {
  const DashboardSidebar({
    super.key,
    required this.selectedPage,
    required this.managementExpanded,
    required this.onSelectPage,
    required this.onToggleManagement,
    required this.onShowModules,
    required this.onOpenWorkspace,
    required this.onHelp,
  });

  final String selectedPage;
  final bool managementExpanded;
  final ValueChanged<String> onSelectPage;
  final VoidCallback onToggleManagement;
  final VoidCallback onShowModules;
  final ValueChanged<String> onOpenWorkspace;
  final VoidCallback onHelp;

  @override
  ConsumerState<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends ConsumerState<DashboardSidebar> {
  final _scrollController = ScrollController();
  String get selectedPage => dashboardPageLabel(widget.selectedPage);
  bool get organizationExpanded =>
      widget.selectedPage.endsWith(_organizationExpandedSuffix);
  bool get managementExpanded => widget.managementExpanded;
  ValueChanged<String> get onSelectPage => widget.onSelectPage;
  VoidCallback get onToggleManagement => widget.onToggleManagement;
  VoidCallback get onShowModules => widget.onShowModules;
  ValueChanged<String> get onOpenWorkspace => widget.onOpenWorkspace;
  VoidCallback get onHelp => widget.onHelp;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        ref.watch(authStateProvider).identity?.isSuperAdmin == true;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCEBFA)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(),
          const SizedBox(height: 20),
          Expanded(
            child: ScrollbarTheme(
              data: const ScrollbarThemeData(
                thumbColor: WidgetStatePropertyAll(Color(0xFF86BDF1)),
                trackColor: WidgetStatePropertyAll(Color(0xFFEAF3FC)),
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                thickness: 5,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OrganizationSelector(),
                      const SizedBox(height: 14),
                      DashboardNavTile(
                        icon: Icons.dashboard_customize,
                        title: 'Resumen ejecutivo',
                        selected: selectedPage == 'Resumen ejecutivo',
                        onTap: () => onSelectPage('Resumen ejecutivo'),
                      ),
                      const SizedBox(height: 13),
                      const Padding(
                        padding: EdgeInsets.only(left: 7, bottom: 6),
                        child: Text(
                          'ESPACIOS DE GESTIÓN',
                          style: TextStyle(
                            color: AppTheme.dashboardMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                      if (isSuperAdmin)
                        DashboardNavTile(
                          icon: Icons.people_alt_outlined,
                          title: 'Organización',
                          subtitle: 'Empresas y personas',
                          selected:
                              selectedPage == 'Organización' ||
                              selectedPage == 'Gestión de Cuentas' ||
                              selectedPage == 'Gestión de Empresas',
                          expanded: organizationExpanded,
                          onTap: () => onSelectPage(
                            organizationExpanded
                                ? selectedPage
                                : dashboardPageSelection(
                                    selectedPage,
                                    organizationExpanded: true,
                                  ),
                          ),
                        ),
                      if (isSuperAdmin)
                        _animatedSubmenu(
                          expanded: organizationExpanded,
                          children: [
                            _subNav(
                              'Gestión de Cuentas',
                              () => onOpenWorkspace('Gestión de Cuentas'),
                            ),
                            _subNav(
                              'Gestión de Empresas',
                              () => onOpenWorkspace('Gestión de Empresas'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 5),
                      DashboardNavTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Gestión SG-SST',
                        subtitle: '11 módulos',
                        selected:
                            selectedPage == 'Gestión SG-SST' ||
                            dashboardManagementModules.contains(selectedPage),
                        expanded: managementExpanded,
                        onTap: onToggleManagement,
                      ),
                      _animatedSubmenu(
                        expanded: managementExpanded,
                        children: [
                          for (final module in dashboardManagementModules)
                            _subNav(module, () => onOpenWorkspace(module)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      DashboardNavTile(
                        icon: Icons.bar_chart,
                        title: 'Inteligencia',
                        subtitle: 'Indicadores y reportes',
                        selected: selectedPage == 'Inteligencia',
                        expanded: false,
                        onTap: () => onOpenWorkspace('Inteligencia'),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(7, 13, 7, 10),
                        child: Divider(
                          height: 1,
                          color: AppTheme.dashboardLine,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 7, bottom: 8),
                        child: Text(
                          'ACCESOS RÁPIDOS',
                          style: TextStyle(
                            color: AppTheme.dashboardMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _quickTile(
                              'Documentos',
                              Icons.description_outlined,
                              AppTheme.dashboardBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _quickTile(
                              'Aprobaciones',
                              Icons.verified,
                              AppTheme.dashboardGreen,
                              badge: '3',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _quickTile(
                              'Agenda',
                              Icons.calendar_month_outlined,
                              AppTheme.dashboardBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _quickTile(
                              'Auditoría',
                              Icons.manage_search,
                              AppTheme.dashboardBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _bottomNav(
            'Configuración',
            Icons.settings_outlined,
            () => onOpenWorkspace('Configuración'),
          ),
          _bottomNav('Ayuda y soporte', Icons.help_outline, onHelp),
        ],
      ),
    );
  }

  Widget _brand() => Row(
    children: [
      Container(
        width: 49,
        height: 49,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF238AF5), Color(0xFF66B1FF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Icon(
          Icons.health_and_safety,
          color: Colors.white,
          size: 26,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'SST',
                  style: TextStyle(
                    color: AppTheme.dashboardBlueDark,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF9F0),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'CRM',
                    style: TextStyle(
                      color: AppTheme.dashboardGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'Sistema de Gestión SST',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.dashboardMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _subNav(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(left: 42, top: 2, bottom: 2),
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        decoration: BoxDecoration(
          color: selectedPage == label
              ? AppTheme.dashboardBlue.withValues(alpha: .1)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.circle, color: Color(0xFF7693C3), size: 9),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 12,
                  fontWeight: selectedPage == label
                      ? FontWeight.w800
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _animatedSubmenu({
    required bool expanded,
    required List<Widget> children,
  }) => AnimatedSize(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 230),
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: expanded ? 1 : 0,
        child: IgnorePointer(
          ignoring: !expanded,
          child: AnimatedOpacity(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 170),
            curve: Curves.easeOut,
            opacity: expanded ? 1 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _quickTile(
    String label,
    IconData icon,
    Color color, {
    String? badge,
  }) => InkWell(
    onTap: () => onOpenWorkspace(label),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 68,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dashboardLine),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dashboardBlue.withValues(alpha: .035),
            blurRadius: 9,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Text(
                label,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppTheme.dashboardOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppTheme.dashboardBlueDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _bottomNav(String title, IconData icon, VoidCallback action) =>
      InkWell(
        onTap: action,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.dashboardMuted, size: 19),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.dashboardBlueDark,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.dashboardMuted,
                size: 18,
              ),
            ],
          ),
        ),
      );
}
