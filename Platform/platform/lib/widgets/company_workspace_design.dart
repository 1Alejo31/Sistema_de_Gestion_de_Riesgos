import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/organization.dart';
import 'organization_selector.dart';

class CompanySectionDefinition {
  const CompanySectionDefinition(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;
}

const companySections = [
  CompanySectionDefinition(
    'Resumen',
    'Explora la ficha y sus apartados.',
    Icons.space_dashboard_outlined,
  ),
  CompanySectionDefinition(
    'Identificación',
    'Consulta la identidad y el registro de la empresa.',
    Icons.badge_outlined,
  ),
  CompanySectionDefinition(
    'Datos generales',
    'Actividad económica y contacto institucional.',
    Icons.business_outlined,
  ),
  CompanySectionDefinition(
    'Sedes',
    'Ubicaciones y centros de trabajo.',
    Icons.location_on_outlined,
  ),
  CompanySectionDefinition(
    'Procesos y áreas',
    'Estructura y actividades de la organización.',
    Icons.account_tree_outlined,
  ),
  CompanySectionDefinition(
    'Trabajadores',
    'Caracterización de los grupos de trabajo.',
    Icons.groups_outlined,
  ),
  CompanySectionDefinition(
    'Contratistas y proveedores',
    'Empresas externas y su relación con la organización.',
    Icons.handshake_outlined,
  ),
  CompanySectionDefinition(
    'Comprobar datos',
    'Consulta aspectos que requieren revisión.',
    Icons.fact_check_outlined,
  ),
  CompanySectionDefinition(
    'Personas y roles',
    'Cuentas y acceso dentro de esta empresa.',
    Icons.manage_accounts_outlined,
  ),
];

String _date(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

class CompanySelectionWelcome extends StatelessWidget {
  const CompanySelectionWelcome({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(22),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Container(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 24 : 42,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.dashboardLine),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.dashboardBlueDark,
                      AppTheme.dashboardBlue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: const Icon(
                  Icons.domain_outlined,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'PLANEAR  /  PROCESO 01',
                style: TextStyle(
                  color: AppTheme.dashboardBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Información general\nde la empresa',
                style: TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Una ficha para conectar la identidad, las personas y la estructura de tu organización.',
                style: TextStyle(
                  color: AppTheme.dashboardMuted,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'ELIGE LA EMPRESA CON LA QUE VAS A TRABAJAR',
                style: TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 11,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const OrganizationSelector(),
              const SizedBox(height: 14),
              const Text(
                'Busca por nombre o NIT. Al seleccionar una empresa verás su ficha y sus secciones.',
                style: TextStyle(
                  color: AppTheme.dashboardMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 26),
                child: Divider(color: AppTheme.dashboardLine),
              ),
              Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  for (final index in [2, 4, 8])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          companySections[index].icon,
                          color: AppTheme.dashboardBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          companySections[index].label,
                          style: const TextStyle(
                            color: AppTheme.dashboardBlueDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CompanyContextCard extends StatelessWidget {
  const CompanyContextCard({
    super.key,
    required this.organization,
    this.compact = false,
  });
  final Organization organization;
  final bool compact;

  @override
  Widget build(BuildContext context) => compact
      ? _compactCard(context)
      : Container(
          key: const Key('company_context_card'),
          margin: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF173B65), Color(0xFF21578B), Color(0xFF217AA8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(23),
            boxShadow: [
              BoxShadow(
                color: AppTheme.dashboardBlueDark.withValues(alpha: .13),
                blurRadius: 22,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -55,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                      width: 30,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 90,
                bottom: -80,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .035),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 500;
                    final change = OutlinedButton.icon(
                      key: const Key('company_change_organization'),
                      onPressed: () => showOrganizationPicker(context),
                      icon: const Icon(Icons.swap_horiz, size: 17),
                      label: const Text('Cambiar empresa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: .08),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: .3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'FICHA EMPRESARIAL  /  PLANEAR',
                                style: TextStyle(
                                  color: Color(0xFFB9E4FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                            if (!compact) change,
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (!compact) ...[
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .2),
                                  ),
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: Colors.white,
                                  size: 31,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: Text(
                                organization.legalName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 22 : 27,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 9,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _contextTag(
                              Icons.badge_outlined,
                              'NIT ${organization.legalId}',
                            ),
                            _contextTag(
                              Icons.circle,
                              organization.status == 'ACTIVE'
                                  ? 'Empresa activa'
                                  : organization.status == 'INACTIVE'
                                  ? 'Empresa inactiva'
                                  : organization.status,
                              status: organization.status == 'ACTIVE',
                            ),
                            if (!compact)
                              Text(
                                'Registrada el ${_date(organization.createdAt)}',
                                style: const TextStyle(
                                  color: Color(0xFFD0E4F3),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        if (compact) ...[const SizedBox(height: 12), change],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );

  Widget _compactCard(BuildContext context) => Container(
    key: const Key('company_context_card'),
    margin: const EdgeInsets.fromLTRB(18, 10, 18, 16),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF173B65), Color(0xFF217AA8)],
      ),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        const Icon(Icons.apartment_rounded, color: Color(0xFFB9E4FF), size: 27),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                organization.legalName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'NIT ${organization.legalId} · ${organization.status == 'ACTIVE'
                    ? 'Activa'
                    : organization.status == 'INACTIVE'
                    ? 'Inactiva'
                    : organization.status}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFD0E4F3), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const Key('company_change_organization'),
          tooltip: 'Cambiar empresa',
          onPressed: () => showOrganizationPicker(context),
          icon: const Icon(Icons.swap_horiz, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _contextTag(IconData icon, String label, {bool status = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: (status ? const Color(0xFF63E4B4) : Colors.white).withValues(
            alpha: .12,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: status ? const Color(0xFF8AF2C8) : const Color(0xFFD3E8FA),
              size: status ? 7 : 13,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class CompanySectionNavigation extends StatefulWidget {
  const CompanySectionNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  State<CompanySectionNavigation> createState() =>
      _CompanySectionNavigationState();
}

class _CompanySectionNavigationState extends State<CompanySectionNavigation> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(double distance) {
    _scroll.animateTo(
      (_scroll.offset + distance).clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      final titleWidth = compact
          ? constraints.maxWidth - 62
          : (constraints.maxWidth * .35).clamp(240.0, 350.0);
      return ColoredBox(
        color: const Color(0xFF46617D),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _folderTitle(titleWidth, compact ? 72 : 80),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _buttons(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: compact ? 16 : 18),
                    child: _controls(),
                  ),
                ],
              ),
            ),
            if (compact)
              ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: _buttons(),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _folderTitle(double width, double height) {
    final section = companySections[widget.selected];
    return Material(
      key: const Key('company_active_folder'),
      color: Colors.white,
      shape: const _FolderTabBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 38, 0),
          child: Row(
            children: [
              Icon(section.icon, color: AppTheme.dashboardBlue, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Align(
                    key: ValueKey(widget.selected),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      section.label,
                      key: const Key('company_folder_title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.dashboardBlueDark,
                        fontSize: width < 260 && section.label.length > 20
                            ? 16
                            : 20,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttons() => SingleChildScrollView(
    controller: _scroll,
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < companySections.length; i++)
          if (i != widget.selected)
            Padding(
              padding: EdgeInsets.only(
                right: i == companySections.length - 1 ? 0 : 6,
              ),
              child: _section(i),
            ),
      ],
    ),
  );

  Widget _controls() => SizedBox(
    width: 46,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${(widget.selected + 1).toString().padLeft(2, '0')} / 09',
          style: const TextStyle(
            color: Color(0xFFDCE8F3),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _arrow(Icons.chevron_left, 'Secciones anteriores', -330),
            _arrow(Icons.chevron_right, 'Secciones siguientes', 330),
          ],
        ),
      ],
    ),
  );

  Widget _arrow(IconData icon, String tooltip, double distance) => SizedBox(
    width: 23,
    height: 23,
    child: IconButton(
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      onPressed: () => _move(distance),
      icon: Icon(icon, size: 18, color: Colors.white),
    ),
  );

  Widget _section(int index) {
    final section = companySections[index];
    return Semantics(
      key: ValueKey('company_option_$index'),
      selected: false,
      child: Tooltip(
        message: section.description,
        child: Material(
          color: const Color(0xFFF4F7FA),
          shape: const StadiumBorder(
            side: BorderSide(color: Color(0xFFE0E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('company_tab_$index'),
            customBorder: const StadiumBorder(),
            onTap: () {
              FocusScope.of(context).unfocus();
              widget.onSelected(index);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(section.icon, size: 16, color: AppTheme.dashboardMuted),
                  const SizedBox(width: 7),
                  Text(
                    section.label,
                    style: const TextStyle(
                      color: AppTheme.dashboardMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Open-bottom tabs join the white document surface like a folder divider.
class _FolderTabBorder extends ShapeBorder {
  const _FolderTabBorder();
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  ShapeBorder scale(double t) => this;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final w = rect.width;
    final h = rect.height;
    return (Path()
          ..moveTo(0, h)
          ..cubicTo(6, h, 10, h - 7, 10, h - 19)
          ..lineTo(10, 23)
          ..quadraticBezierTo(10, 0, 34, 0)
          ..lineTo(w - 70, 0)
          ..cubicTo(w - 28, 0, w - 40, h, w, h)
          ..close())
        .shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}

class CompanyFolder extends StatelessWidget {
  const CompanyFolder({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.child,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    key: const Key('company_folder'),
    margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFC8D9EB)),
      boxShadow: [
        BoxShadow(
          color: AppTheme.dashboardBlueDark.withValues(alpha: .06),
          blurRadius: 20,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      children: [
        CompanySectionNavigation(selected: selected, onSelected: onSelected),
        Expanded(
          child: ColoredBox(color: Colors.white, child: child),
        ),
      ],
    ),
  );
}

class CompanyOverview extends StatelessWidget {
  const CompanyOverview({
    super.key,
    required this.organization,
    required this.onSelected,
    this.identificationOnly = false,
  });
  final Organization organization;
  final ValueChanged<int> onSelected;
  final bool identificationOnly;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        identificationOnly
            ? 'Identidad y registro'
            : 'Una visión clara de tu organización',
        style: const TextStyle(
          color: AppTheme.dashboardBlueDark,
          fontSize: 23,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        identificationOnly
            ? 'Datos de identificación de la empresa seleccionada.'
            : 'Elige un apartado para consultar o actualizar la información de esta empresa.',
        style: const TextStyle(
          color: AppTheme.dashboardMuted,
          fontSize: 13,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 22),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in [
              (Icons.business_outlined, 'RAZÓN SOCIAL', organization.legalName),
              (
                Icons.badge_outlined,
                'IDENTIFICACIÓN TRIBUTARIA',
                organization.legalId,
              ),
              (
                Icons.event_available_outlined,
                'REGISTRO EN LA PLATAFORMA',
                _date(organization.createdAt),
              ),
              (
                Icons.verified_user_outlined,
                'ESTADO DE LA EMPRESA',
                organization.status == 'ACTIVE'
                    ? 'Activa'
                    : organization.status == 'INACTIVE'
                    ? 'Inactiva'
                    : organization.status,
              ),
            ])
              SizedBox(
                width: constraints.maxWidth >= 600
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dashboardLine),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.dashboardBlue.withValues(alpha: .07),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          entry.$1,
                          color: AppTheme.dashboardBlue,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.$2,
                              style: const TextStyle(
                                color: AppTheme.dashboardMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.$3,
                              style: const TextStyle(
                                color: AppTheme.dashboardBlueDark,
                                fontSize: 15,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      if (!identificationOnly) ...[
        const SizedBox(height: 28),
        const Text(
          'Construye la ficha de tu empresa',
          style: TextStyle(
            color: AppTheme.dashboardBlueDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 2; i < companySections.length; i++)
                SizedBox(
                  width: constraints.maxWidth >= 600
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth,
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.dashboardLine),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelected(i),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Icon(
                              companySections[i].icon,
                              color: AppTheme.dashboardBlue,
                              size: 25,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companySections[i].label,
                                    style: const TextStyle(
                                      color: AppTheme.dashboardBlueDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    companySections[i].description,
                                    style: const TextStyle(
                                      color: AppTheme.dashboardMuted,
                                      fontSize: 11,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_outward_rounded,
                              color: AppTheme.dashboardBlue,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ],
  );
}
