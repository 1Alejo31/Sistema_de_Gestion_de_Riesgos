import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_clock.dart';
import '../widgets/dashboard_assistant_panel.dart';
import '../widgets/dashboard_assistant_access.dart';
import '../providers/auth_providers.dart';
import '../models/user_account.dart';
import '../models/organization.dart';
import 'accounts_page.dart';
import 'organizations_page.dart';
import 'company_information_page.dart';
import '../widgets/create_account_dialog.dart';
import '../widgets/create_organization_dialog.dart';
import '../widgets/operation_success_dialog.dart';
import '../providers/users_providers.dart';
import '../providers/organizations_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String get _company =>
      ref.read(selectedOrganizationProvider)?.legalName ??
      'Sin empresa seleccionada';
  String _chartMode = 'Cumplimiento SG-SST';
  String _search = '';
  String _selectedPage = 'Resumen ejecutivo';
  bool _managementExpanded = false;
  final Set<String> _scheduled = {};
  final Set<String> _approved = {};

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Buenos días';
    if (hour >= 12 && hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  static const _documents = [
    _DocumentRow(
      'Procedimiento de emergencias',
      'v2.1 · Actualizado por Laura Pérez',
      'Hace 2 horas',
      'v2.1',
      Icons.description_outlined,
      AppTheme.dashboardGreen,
    ),
    _DocumentRow(
      'Matriz de peligros',
      'v3.0 · Revisado por Carlos Ramírez',
      'Hace 4 horas',
      'v3.0',
      Icons.table_chart_outlined,
      AppTheme.dashboardBlue,
    ),
    _DocumentRow(
      'Plan anual SST 2024',
      'v1.2 · Editado por Andrea Torres',
      'Hace 6 horas',
      'v1.2',
      Icons.assignment_outlined,
      AppTheme.dashboardOrange,
    ),
    _DocumentRow(
      'Informe de inspección',
      'v1.0 · Creado por Miguel Soto',
      'Ayer 10:24',
      'v1.0',
      Icons.edit_document,
      AppTheme.dashboardPurple,
    ),
    _DocumentRow(
      'Política SST',
      'v2.3 · Aprobado por María González',
      'Ayer 16:18',
      'v2.3',
      Icons.verified_user_outlined,
      AppTheme.dashboardGreen,
    ),
  ];
  static const _dueItems = [
    _DueRow(
      'Renovación de exámenes médicos',
      'Andino Textil S.A.S.',
      '12 abr 2024',
      '3',
      'Por vencer',
      AppTheme.dashboardRed,
    ),
    _DueRow(
      'Inspección de extintores',
      'Logística Andina',
      '18 abr 2024',
      '9',
      'Programado',
      AppTheme.dashboardOrange,
    ),
    _DueRow(
      'Cierre de acciones correctivas',
      'Alimentos del Valle',
      '25 abr 2024',
      '16',
      'En proceso',
      AppTheme.dashboardBlue,
    ),
    _DueRow(
      'Actualización matriz de peligros',
      'Constructora Andina',
      '30 abr 2024',
      '21',
      'Programado',
      AppTheme.dashboardGreen,
    ),
    _DueRow(
      'Informe de indicadores',
      'Grupo Andino',
      '30 abr 2024',
      '21',
      'Programado',
      AppTheme.dashboardBlue,
    ),
  ];

  List<double> get _chartValues => _chartMode == 'Riesgos gestionados'
      ? const [68, 73, 77, 76, 78, 82, 81, 86, 85, 89, 91, 94]
      : _chartMode == 'Plan anual'
      ? const [61, 65, 69, 71, 73, 75, 74, 79, 81, 83, 86, 90]
      : const [68, 73, 77, 76, 78, 83, 82, 86, 85, 87, 90, 92];

  List<_DueRow> get _filteredDue => _dueItems
      .where((e) => _matches('${e.task} ${e.company} ${e.status}'))
      .toList();
  List<_DocumentRow> get _filteredDocuments => _documents
      .where((e) => _matches('${e.title} ${e.subtitle} ${e.version}'))
      .toList();
  bool _matches(String value) =>
      _search.trim().isEmpty ||
      value.toLowerCase().contains(_search.trim().toLowerCase());

  bool get _isAccountsPage =>
      ModalRoute.of(context)?.settings.name == '/accounts';
  bool get _isOrganizationsPage =>
      ModalRoute.of(context)?.settings.name == '/organizations';
  bool get _isCompanyInformationPage =>
      ModalRoute.of(context)?.settings.name == '/company-information';
  bool get _isWorkspacePage =>
      _isAccountsPage || _isOrganizationsPage || _isCompanyInformationPage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isCompanyInformationPage && _selectedPage == 'Resumen ejecutivo') {
      _selectedPage = dashboardManagementModules.first;
      _managementExpanded = true;
    }
    if (_isWorkspacePage && _selectedPage == 'Resumen ejecutivo') {
      _selectedPage = dashboardPageSelection(
        _isAccountsPage ? 'Gestión de Cuentas' : 'Gestión de Empresas',
        organizationExpanded: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final identity = auth.identity;
    // A session can end before the route guard removes this widget.
    if (!auth.isAuthenticated || identity == null) {
      return const Scaffold(
        body: Center(child: Text('Volviendo al inicio de sesión…')),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1390;
    final hasSidebar = width >= 1100;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.dashboardBackground,
      drawer: hasSidebar ? null : Drawer(width: 290, child: _sidebarWidget()),
      endDrawer: isWide
          ? null
          : DashboardAssistantDrawer(child: _assistantWidget()),
      endDrawerEnableOpenDragGesture: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: isWide
          ? null
          : DashboardAssistantLauncher(
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasSidebar) SizedBox(width: 280, child: _sidebarWidget()),
            Expanded(
              child: Column(
                children: [
                  if (_isCompanyInformationPage)
                    DashboardCompanyHeader(
                      identity: identity,
                      isWide: hasSidebar,
                      onProfileAction: _handleProfileAction,
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                    )
                  else
                    DashboardHeader(
                      identity: identity,
                      isWide: hasSidebar,
                      onSearchChanged: (value) =>
                          setState(() => _search = value),
                      onNotificationSelected: (value) =>
                          _showDetail('Notificación', value),
                      onProfileAction: _handleProfileAction,
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                      onCreateAccount: _isAccountsPage
                          ? _showCreateAccount
                          : null,
                      onCreateOrganization: _isOrganizationsPage
                          ? _showCreateOrganization
                          : null,
                      searchHint: _isAccountsPage
                          ? 'Buscar por correo, rol, estado o alcance…'
                          : _isOrganizationsPage
                          ? 'Buscar por razón social, NIT o estado…'
                          : null,
                    ),
                  Expanded(
                    child: _isAccountsPage
                        ? AccountsPage(
                            search: _search,
                            bottomPadding: isWide ? 18 : 96,
                          )
                        : _isOrganizationsPage
                        ? OrganizationsPage(
                            search: _search,
                            bottomPadding: isWide ? 18 : 96,
                          )
                        : _isCompanyInformationPage
                        ? CompanyInformationPage(
                            bottomPadding: isWide ? 18 : 96,
                          )
                        : _dashboardBody(bottomPadding: isWide ? 18 : 96),
                  ),
                ],
              ),
            ),
            if (isWide) SizedBox(width: 360, child: _assistantWidget()),
          ],
        ),
      ),
    );
  }

  Widget _assistantWidget() => DashboardAssistantPanel(
    scheduled: _scheduled,
    approved: _approved,
    onOpenSuggestion: _openSuggestion,
    onReviewProposals: _showProposals,
  );

  Widget _sidebarWidget() => DashboardSidebar(
    selectedPage: _selectedPage,
    managementExpanded: _managementExpanded,
    onSelectPage: _selectPage,
    onToggleManagement: () =>
        setState(() => _managementExpanded = !_managementExpanded),
    onShowModules: _showModules,
    onOpenWorkspace: _openWorkspace,
    onHelp: _showHelp,
  );

  void _selectPage(String value) {
    if (_isWorkspacePage && value == 'Resumen ejecutivo') {
      _scaffoldKey.currentState?.closeDrawer();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
      return;
    }
    setState(() {
      _selectedPage = value;
      if (value == 'Resumen ejecutivo') _managementExpanded = false;
    });
  }

  Future<void> _showCreateAccount() async {
    await showDialog<UserAccount>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateAccountDialog(
        onAccountCreated: () => ref.invalidate(userAccountsProvider),
        onCreateAccount: ref.read(usersServiceProvider).createUser,
        existingEmails:
            ref
                .read(userAccountsProvider)
                .asData
                ?.value
                .map((account) => account.email)
                .toList() ??
            const [],
      ),
    );
  }

  Future<void> _showCreateOrganization() async {
    final created = await showDialog<Organization>(
      context: context,
      builder: (context) => CreateOrganizationDialog(
        onCreateOrganization: ref
            .read(organizationsServiceProvider)
            .createOrganization,
        existingLegalIds:
            ref
                .read(organizationsProvider)
                .asData
                ?.value
                .map((organization) => organization.legalId)
                .toList() ??
            const [],
      ),
    );
    if (created != null && mounted) {
      ref.invalidate(organizationsProvider);
      await showDialog<void>(
        context: context,
        builder: (context) => OperationSuccessDialog(
          key: const Key('organization_created_alert'),
          detailKey: const Key('organization_created_name'),
          confirmKey: const Key('organization_created_confirm'),
          title: '¡Empresa registrada con éxito!',
          description:
              'La empresa y su administradora inicial ya están registradas.',
          detail: created.legalName,
        ),
      );
    }
  }

  void _handleProfileAction(String value) {
    final auth = ref.read(authControllerProvider);
    if (value == 'Salir') {
      auth.logout();
    } else if (value == 'Perfil') {
      final identity = auth.identity;
      if (identity == null || !auth.isAuthenticated) return;
      _showDetail(
        'Mi perfil',
        '${identity.email}\nEstado: ${identity.status}\nAlcance global: ${identity.scope}\nRoles globales: ${identity.roles.join(', ')}',
      );
    } else if (value != 'Perfil') {
      _showDetail(
        value,
        'Vista de demostración. No se han conectado opciones de configuración.',
      );
    }
  }

  Widget _dashboardBody({double bottomPadding = 18}) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Datos de demostración · Empresas, indicadores y propuestas no corresponden a tu cuenta autenticada.',
              key: Key('demo_notice'),
              style: TextStyle(color: AppTheme.dashboardMuted, fontSize: 12),
            ),
          ),
          _greetingBanner(),
          const SizedBox(height: 14),
          _metricGrid(constraints.maxWidth),
          const SizedBox(height: 13),
          if (constraints.maxWidth >= 690)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _trendPanel()),
                const SizedBox(width: 12),
                Expanded(child: _riskPanel()),
              ],
            )
          else
            Column(
              children: [
                _trendPanel(),
                const SizedBox(height: 12),
                _riskPanel(),
              ],
            ),
          const SizedBox(height: 13),
          if (constraints.maxWidth >= 780)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: _duePanel()),
                const SizedBox(width: 12),
                Expanded(flex: 9, child: _documentsPanel()),
              ],
            )
          else
            Column(
              children: [
                _duePanel(),
                const SizedBox(height: 12),
                _documentsPanel(),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _greetingBanner() => Container(
    height: 116,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      color: AppTheme.dashboardBlueDark,
      boxShadow: [
        BoxShadow(
          color: AppTheme.dashboardBlueDark.withValues(alpha: .15),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/dashboard_mountain_banner.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.dashboardBlueDark.withValues(alpha: .96),
                AppTheme.dashboardBlueDark.withValues(alpha: .65),
                AppTheme.dashboardBlueDark.withValues(alpha: .12),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _timeGreeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: constraints.maxWidth < 480 ? 22 : 28,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Aquí tienes el panorama en SST',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (constraints.maxWidth > 570)
                  Container(
                    width: 1,
                    height: 62,
                    color: Colors.white.withValues(alpha: .35),
                  ),
                if (constraints.maxWidth > 570) const SizedBox(width: 20),
                if (constraints.maxWidth > 570)
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white,
                    size: 23,
                  ),
                if (constraints.maxWidth > 570) const SizedBox(width: 10),
                if (constraints.maxWidth > 570) const DashboardClock(),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _metricGrid(double width) {
    final columns = width >= 850
        ? 4
        : width >= 480
        ? 2
        : 1;
    final spacing = 11.0;
    final cardWidth = (width - spacing * (columns - 1)) / columns;
    final items = [
      _MetricData(
        'Cumplimiento SG-SST',
        '92%',
        '↑ +4% vs. mes anterior',
        Icons.verified_user,
        AppTheme.dashboardGreen,
        .88,
        'Meta: 90%',
      ),
      _MetricData(
        'Riesgos críticos',
        '8',
        '↓ -3 vs. mes anterior',
        Icons.warning_amber_rounded,
        AppTheme.dashboardOrange,
        .36,
        'Total identificados: 142',
      ),
      _MetricData(
        'Plan anual',
        '78%',
        '↑ +6% vs. mes anterior',
        Icons.event_available,
        AppTheme.dashboardBlue,
        .78,
        'Meta: 85%',
      ),
      _MetricData(
        'Capacitación',
        '87%',
        '↑ +5% vs. mes anterior',
        Icons.school_outlined,
        AppTheme.dashboardPurple,
        .87,
        'Meta: 85%',
      ),
    ];
    return Wrap(
      spacing: spacing,
      runSpacing: 10,
      children: items
          .map(
            (m) => SizedBox(
              width: cardWidth,
              child: DashboardMetricCard(
                title: m.title,
                value: m.value,
                change: m.change,
                icon: m.icon,
                color: m.color,
                progress: m.progress,
                footer: m.footer,
                onTap: () => _showDetail(
                  m.title,
                  'Resumen para $_company.\n\n${m.value} · ${m.change}',
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _trendPanel() => DashboardCard(
    child: Column(
      children: [
        const DashboardHeading(
          'Evolución del cumplimiento SG-SST',
          icon: Icons.bar_chart,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => _chartMode = value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'Cumplimiento SG-SST',
                  child: Text('Cumplimiento SG-SST'),
                ),
                PopupMenuItem(
                  value: 'Riesgos gestionados',
                  child: Text('Riesgos gestionados'),
                ),
                PopupMenuItem(value: 'Plan anual', child: Text('Plan anual')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dashboardLine),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _chartMode,
                      style: const TextStyle(
                        color: AppTheme.dashboardBlueDark,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        ComplianceTrendChart(
          values: _chartValues,
          labels: _months,
          currentLabel: '${_chartValues.last.round()}%',
        ),
      ],
    ),
  );

  Widget _riskPanel() => DashboardCard(
    child: Column(
      children: [
        const DashboardHeading(
          'Distribución de riesgos',
          icon: Icons.hexagon_outlined,
        ),
        const SizedBox(height: 4),
        const RiskDistributionChart(),
      ],
    ),
  );

  Widget _duePanel() => DashboardCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardHeading(
          'Próximos vencimientos',
          icon: Icons.event_note,
          action: 'Ver todos',
          onAction: () => _showAllDue(),
        ),
        const SizedBox(height: 8),
        _dueTable(),
      ],
    ),
  );

  Widget _dueTable() {
    final items = _filteredDue;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF7FE),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Row(
            children: [
              Expanded(flex: 5, child: Text('Tarea', style: _tableHeader)),
              Expanded(flex: 4, child: Text('Empresa', style: _tableHeader)),
              Expanded(
                flex: 3,
                child: Text('Fecha límite', style: _tableHeader),
              ),
              SizedBox(width: 29, child: Text('Días', style: _tableHeader)),
              SizedBox(width: 68, child: Text('Estado', style: _tableHeader)),
            ],
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay tareas para esta búsqueda.',
              style: TextStyle(color: AppTheme.dashboardMuted, fontSize: 12),
            ),
          )
        else
          ...items.map(
            (item) => InkWell(
              onTap: () => _showDetail(
                item.task,
                '${item.company}\nFecha límite: ${item.date}\nEstado: ${item.status}',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEDF4FB))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Icon(
                            Icons.assignment_late_outlined,
                            color: item.color,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.task,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.dashboardBlueDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        item.company,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.dashboardMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.date,
                        style: const TextStyle(
                          color: AppTheme.dashboardMuted,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 29,
                      child: Center(
                        child: DashboardStatusPill(
                          item.days,
                          color: item.color,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 68,
                      child: Center(
                        child: DashboardStatusPill(
                          item.status,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _documentsPanel() => DashboardCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardHeading(
          'Actividad reciente de documentos',
          icon: Icons.description,
          action: 'Ver todos',
          onAction: () => _showAllDocuments(),
        ),
        const SizedBox(height: 7),
        ..._filteredDocuments.map(
          (doc) => InkWell(
            onTap: () => _showDetail(
              doc.title,
              '${doc.subtitle}\nVersión actual: ${doc.version}\n\nDocumento disponible para revisión en el espacio Documentos.',
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: doc.color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(doc.icon, size: 17, color: doc.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.dashboardBlueDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          doc.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.dashboardMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        doc.updated,
                        style: const TextStyle(
                          color: AppTheme.dashboardMuted,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 3),
                      DashboardStatusPill(doc.version, color: doc.color),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_filteredDocuments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay documentos para esta búsqueda.',
              style: TextStyle(color: AppTheme.dashboardMuted, fontSize: 12),
            ),
          ),
      ],
    ),
  );

  void _openWorkspace(String name) {
    if (name == dashboardManagementModules.first) {
      _scaffoldKey.currentState?.closeDrawer();
      if (!_isCompanyInformationPage) {
        Navigator.of(context).pushNamed('/company-information');
      }
      return;
    }
    if (name == 'Gestión de Cuentas') {
      _scaffoldKey.currentState?.closeDrawer();
      if (!_isAccountsPage) Navigator.of(context).pushNamed('/accounts');
      return;
    }
    if (name == 'Gestión de Empresas') {
      _scaffoldKey.currentState?.closeDrawer();
      if (!_isOrganizationsPage) {
        Navigator.of(context).pushNamed('/organizations');
      }
      return;
    }
    final keepOrganizationExpanded =
        _selectedPage != dashboardPageLabel(_selectedPage);
    setState(() {
      _selectedPage = dashboardPageSelection(
        name,
        organizationExpanded: keepOrganizationExpanded,
      );
    });
    _showDetail(
      name,
      'Este espacio de gestión está listo para conectar sus formularios, registros y procesos del SG-SST.\n\nOrganización: $_company',
    );
  }

  void _showModules() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Módulos de gestión SG-SST'),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: dashboardManagementModules
              .map(
                (e) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.dashboardBlue,
                  ),
                  title: Text(e, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  void _showHelp() => _showDetail(
    'Ayuda y soporte',
    'Centro de ayuda SST\n\nConsulta las guías de uso, revisa preguntas frecuentes o contacta al equipo de acompañamiento.',
  );

  void _showDetail(String title, String body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  void _showAllDue() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Todos los vencimientos'),
      content: SizedBox(
        width: 520,
        child: ListView(
          shrinkWrap: true,
          children: _dueItems
              .map(
                (e) => ListTile(
                  dense: true,
                  leading: Icon(Icons.event_note, color: e.color),
                  title: Text(e.task),
                  subtitle: Text('${e.company} · ${e.date}'),
                  trailing: DashboardStatusPill(e.status, color: e.color),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  void _showAllDocuments() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Actividad de documentos'),
      content: SizedBox(
        width: 520,
        child: ListView(
          shrinkWrap: true,
          children: _documents
              .map(
                (e) => ListTile(
                  dense: true,
                  leading: Icon(e.icon, color: e.color),
                  title: Text(e.title),
                  subtitle: Text(e.subtitle),
                  trailing: Text(e.version),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  void _openSuggestion(String id) {
    const suggestions = {
      'critical': (
        'Intervenir riesgo crítico',
        'Ruido en planta de producción (Bogotá)',
      ),
      'training': (
        'Programar capacitación',
        'Trabajo en alturas · 48 trabajadores',
      ),
      'document': ('Actualizar documento', 'Procedimiento de emergencias'),
    };
    final suggestion = suggestions[id];
    if (suggestion != null) {
      _showSuggestion(id, suggestion.$1, suggestion.$2);
    }
  }

  void _showSuggestion(
    String id,
    String title,
    String detail,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(
        '$detail\n\nSugerencia generada por el análisis de la información del SG-SST. La acción requiere aprobación de un responsable.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Después'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              if (id == 'training') {
                _scheduled.add(id);
              } else {
                _approved.add(id);
              }
            });
            Navigator.pop(context);
          },
          child: Text(id == 'training' ? 'Programar' : 'Aprobar'),
        ),
      ],
    ),
  );

  void _showProposals() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Propuestas de la asesora SST'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in const [
              ('critical', 'Intervenir riesgo crítico'),
              ('training', 'Programar capacitación'),
              ('document', 'Actualizar documento'),
            ])
              ListTile(
                leading: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.dashboardBlue,
                ),
                title: Text(item.$2),
                trailing: _approved.contains(item.$1)
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.dashboardGreen,
                      )
                    : TextButton(
                        onPressed: () => setState(() => _approved.add(item.$1)),
                        child: const Text('Aprobar'),
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Listo'),
        ),
      ],
    ),
  );
}

class _MetricData {
  const _MetricData(
    this.title,
    this.value,
    this.change,
    this.icon,
    this.color,
    this.progress,
    this.footer,
  );
  final String title, value, change, footer;
  final IconData icon;
  final Color color;
  final double progress;
}

class _DueRow {
  const _DueRow(
    this.task,
    this.company,
    this.date,
    this.days,
    this.status,
    this.color,
  );
  final String task, company, date, days, status;
  final Color color;
}

class _DocumentRow {
  const _DocumentRow(
    this.title,
    this.subtitle,
    this.updated,
    this.version,
    this.icon,
    this.color,
  );
  final String title, subtitle, updated, version;
  final IconData icon;
  final Color color;
}

const _tableHeader = TextStyle(
  color: AppTheme.dashboardMuted,
  fontSize: 9,
  fontWeight: FontWeight.w700,
);
