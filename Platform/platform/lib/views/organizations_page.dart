import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../models/api_failure.dart';
import '../models/organization.dart';
import '../providers/organizations_providers.dart';
import '../widgets/dashboard_widgets.dart';

class OrganizationsPage extends ConsumerStatefulWidget {
  const OrganizationsPage({
    super.key,
    this.search = '',
    this.bottomPadding = 18,
  });

  final String search;
  final double bottomPadding;

  @override
  ConsumerState<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends ConsumerState<OrganizationsPage> {
  final _tableScrollController = ScrollController();
  int _pageIndex = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  static const _pageSize = 10;

  @override
  void didUpdateWidget(covariant OrganizationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search) _pageIndex = 0;
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, widget.bottomPadding),
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.dashboardBlue.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_outlined,
                    color: AppTheme.dashboardBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gestión de Empresas',
                    style: TextStyle(
                      color: AppTheme.dashboardBlueDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar empresas',
                  onPressed: organizations.isLoading
                      ? null
                      : () => ref.invalidate(organizationsProvider),
                  icon: const Icon(Icons.refresh),
                  color: AppTheme.dashboardBlue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Consulta las empresas registradas y sus datos legales.',
              style: TextStyle(color: AppTheme.dashboardMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            organizations.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.dashboardBlue),
                    SizedBox(height: 16),
                    Text(
                      'Cargando empresas…',
                      style: TextStyle(color: AppTheme.dashboardMuted),
                    ),
                  ],
                ),
              ),
              error: _error,
              data: _table,
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(Object error, StackTrace stackTrace) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: AppTheme.dashboardRed, size: 32),
        const SizedBox(height: 12),
        Text(
          error is ApiFailure
              ? error.supportMessage
              : 'No se pudieron cargar las empresas. Intenta nuevamente.',
          key: const Key('organizations_error'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.dashboardBlueDark),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => ref.invalidate(organizationsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.dashboardBlue),
        ),
      ],
    ),
  );

  Widget _table(List<Organization> organizations) {
    final query = widget.search.trim().toLowerCase();
    final terms = query.split(RegExp(r'\s+')).where((term) => term.isNotEmpty);
    final filtered = organizations
        .where(
          (organization) => terms.every(
            '${organization.legalId} ${organization.legalName} ${organization.status}'
                .toLowerCase()
                .contains,
          ),
        )
        .toList();
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Text(
          organizations.isEmpty
              ? 'No hay empresas registradas.'
              : 'No hay empresas que coincidan con la búsqueda.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.dashboardMuted),
        ),
      );
    }
    final columnIndex = _sortColumnIndex;
    if (columnIndex != null) {
      filtered.sort((left, right) {
        final comparison = _compareOrganizations(left, right, columnIndex);
        return _sortAscending ? comparison : -comparison;
      });
    }
    final pageCount = (filtered.length + _pageSize - 1) ~/ _pageSize;
    final page = _pageIndex.clamp(0, pageCount - 1);
    final start = page * _pageSize;
    final visible = filtered.skip(start).take(_pageSize).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) => Scrollbar(
              controller: _tableScrollController,
              thumbVisibility: true,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: SingleChildScrollView(
                controller: _tableScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: Colors.white),
                    child: DataTable(
                      key: const Key('organizations_table'),
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      headingRowColor: const WidgetStatePropertyAll(
                        AppTheme.dashboardBlueDark,
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      dataTextStyle: const TextStyle(
                        color: AppTheme.dashboardBlueDark,
                        fontSize: 12,
                      ),
                      horizontalMargin: 16,
                      columnSpacing: 24,
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 76,
                      dividerThickness: .7,
                      border: const TableBorder(
                        horizontalInside: BorderSide(
                          color: AppTheme.dashboardLine,
                        ),
                      ),
                      columns: [
                        DataColumn(
                          label: const Text('Identificación legal'),
                          onSort: _sortByColumn,
                        ),
                        DataColumn(
                          label: const Text('Razón social'),
                          onSort: _sortByColumn,
                        ),
                        DataColumn(
                          label: const Text('Estado'),
                          onSort: _sortByColumn,
                        ),
                        DataColumn(
                          label: const Text('Fecha de creación'),
                          onSort: _sortByColumn,
                        ),
                      ],
                      rows: [
                        for (var index = 0; index < visible.length; index++)
                          _row(visible[index], start + index),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${start + 1}–${start + visible.length} de ${filtered.length} empresas'
          '${query.isEmpty ? '' : ' · ${organizations.length} registradas'}',
          style: const TextStyle(color: AppTheme.dashboardMuted, fontSize: 12),
        ),
        if (pageCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Página ${page + 1} de $pageCount',
                style: const TextStyle(
                  color: AppTheme.dashboardMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Página anterior',
                color: AppTheme.dashboardBlue,
                onPressed: page == 0
                    ? null
                    : () => setState(() => _pageIndex = page - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Página siguiente',
                key: const Key('organizations_next_page'),
                color: AppTheme.dashboardBlue,
                onPressed: page == pageCount - 1
                    ? null
                    : () => setState(() => _pageIndex = page + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }

  void _sortByColumn(int columnIndex, bool ascending) => setState(() {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _pageIndex = 0;
  });

  int _compareOrganizations(
    Organization left,
    Organization right,
    int columnIndex,
  ) {
    final comparison = switch (columnIndex) {
      0 => left.legalId.toLowerCase().compareTo(right.legalId.toLowerCase()),
      1 => left.legalName.toLowerCase().compareTo(
        right.legalName.toLowerCase(),
      ),
      2 => left.status.toLowerCase().compareTo(right.status.toLowerCase()),
      3 => left.createdAt.compareTo(right.createdAt),
      _ => 0,
    };
    if (comparison != 0) return comparison;
    return left.legalName.toLowerCase().compareTo(
      right.legalName.toLowerCase(),
    );
  }

  DataRow _row(Organization organization, int index) => DataRow(
    color: WidgetStatePropertyAll(
      index.isEven
          ? Colors.white
          : AppTheme.dashboardBackground.withValues(alpha: .4),
    ),
    cells: [
      DataCell(_cell(organization.legalId, width: 190)),
      DataCell(_cell(organization.legalName, width: 280)),
      DataCell(
        DashboardStatusPill(
          organization.status,
          color: organization.status == 'ACTIVE'
              ? AppTheme.dashboardGreen
              : AppTheme.dashboardRed,
        ),
      ),
      DataCell(
        Tooltip(
          message: organization.createdAt.toUtc().toIso8601String(),
          child: Text(_date(organization.createdAt)),
        ),
      ),
    ],
  );

  Widget _cell(String text, {required double width}) => SizedBox(
    width: width,
    child: Tooltip(
      message: text,
      child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
    ),
  );

  String _date(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
