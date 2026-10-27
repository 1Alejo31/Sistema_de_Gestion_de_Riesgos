import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../models/api_failure.dart';
import '../models/user_account.dart';
import '../models/account_membership.dart';
import '../models/membership_options.dart';
import '../providers/users_providers.dart';
import '../providers/organizations_providers.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/link_account_dialog.dart';
import '../widgets/operation_success_dialog.dart';

/// Accounts content inside the same dashboard shell used by Home.
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key, this.search = '', this.bottomPadding = 18});

  final String search;
  final double bottomPadding;

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  final _tableScrollController = ScrollController();
  late int _pageIndex = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  static const _pageSize = 10;

  @override
  void didUpdateWidget(covariant AccountsPage oldWidget) {
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
    final accounts = ref.watch(userAccountsProvider);
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
                    Icons.manage_accounts_outlined,
                    color: AppTheme.dashboardBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gestión de Cuentas',
                    style: TextStyle(
                      color: AppTheme.dashboardBlueDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar cuentas',
                  onPressed: accounts.isLoading
                      ? null
                      : () => ref.invalidate(userAccountsProvider),
                  icon: const Icon(Icons.refresh),
                  color: AppTheme.dashboardBlue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Consulta las cuentas registradas en la plataforma.',
              style: TextStyle(color: AppTheme.dashboardMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            accounts.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.dashboardBlue),
                    SizedBox(height: 16),
                    Text(
                      'Cargando cuentas…',
                      style: TextStyle(color: AppTheme.dashboardMuted),
                    ),
                  ],
                ),
              ),
              error: (error, stackTrace) => _error(error),
              data: _table,
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(Object error) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: AppTheme.dashboardRed, size: 32),
        const SizedBox(height: 12),
        Text(
          error is ApiFailure
              ? error.supportMessage
              : 'No se pudieron cargar las cuentas. Intenta nuevamente.',
          key: const Key('accounts_error'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.dashboardBlueDark),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => ref.invalidate(userAccountsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.dashboardBlue),
        ),
      ],
    ),
  );

  Widget _table(List<UserAccount> accounts) {
    final query = widget.search.trim().toLowerCase();
    final terms = query.split(RegExp(r'\s+')).where((term) => term.isNotEmpty);
    final filtered = accounts
        .where(
          (account) => terms.every(
            '${account.email} ${account.roles.isEmpty ? 'Sin roles' : account.roles.join(' ')} ${account.status} ${account.scope}'
                .toLowerCase()
                .contains,
          ),
        )
        .toList();
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Text(
          accounts.isEmpty
              ? 'No hay cuentas registradas.'
              : 'No hay cuentas que coincidan con la búsqueda.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.dashboardMuted),
        ),
      );
    }
    if (_sortColumnIndex case final columnIndex?) {
      filtered.sort((left, right) {
        final comparison = _compareAccounts(left, right, columnIndex);
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
                      key: const Key('accounts_table'),
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
                          label: const Text('Correo electrónico'),
                          onSort: _sortByColumn,
                        ),
                        DataColumn(
                          label: const Text('Roles'),
                          onSort: _sortByColumn,
                        ),
                        DataColumn(
                          label: const Text('Estado'),
                          onSort: _sortByColumn,
                        ),
                        DataColumn(
                          label: const Text('Alcance'),
                          onSort: _sortByColumn,
                        ),
                        DataColumn(
                          label: const Text('Fecha de creación'),
                          onSort: _sortByColumn,
                        ),
                        DataColumn(label: Text('Acciones')),
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
          '${start + 1}–${start + visible.length} de ${filtered.length} cuentas'
          '${query.isEmpty ? '' : ' · ${accounts.length} registradas'}',
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
                key: const Key('accounts_next_page'),
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

  int _compareAccounts(UserAccount left, UserAccount right, int columnIndex) {
    final comparison = switch (columnIndex) {
      0 => left.email.toLowerCase().compareTo(right.email.toLowerCase()),
      1 => _rolesLabel(
        left,
      ).toLowerCase().compareTo(_rolesLabel(right).toLowerCase()),
      2 => left.status.toLowerCase().compareTo(right.status.toLowerCase()),
      3 => left.scope.toLowerCase().compareTo(right.scope.toLowerCase()),
      4 => left.createdAt.compareTo(right.createdAt),
      _ => 0,
    };
    if (comparison != 0) return comparison;
    return left.email.toLowerCase().compareTo(right.email.toLowerCase());
  }

  String _rolesLabel(UserAccount account) =>
      account.roles.isEmpty ? 'Sin roles' : account.roles.join(', ');

  Future<void> _linkAccount(UserAccount account) async {
    // The menu keeps this provider alive. Refresh before opening the form so
    // an earlier empty catalogue is not reused for a new linking operation.
    ref.invalidate(organizationsProvider);
    final linked = await showDialog<AccountMembership>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LinkAccountDialog(account: account),
    );
    if (linked != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => OperationSuccessDialog(
          key: const Key('account_linked_alert'),
          title: '¡Cuenta vinculada con éxito!',
          description:
              'Rol: ${OrganizationRole(linked.role).label}\nAlcance: ${linked.scope.label}',
          detail: linked.email,
        ),
      );
    }
  }

  DataRow _row(UserAccount account, int index) => DataRow(
    color: WidgetStatePropertyAll(
      index.isEven
          ? Colors.white
          : AppTheme.dashboardBackground.withValues(alpha: .4),
    ),
    cells: [
      DataCell(_cell(account.email, width: 220)),
      DataCell(
        _cell(
          account.roles.isEmpty ? 'Sin roles' : account.roles.join(', '),
          width: 170,
        ),
      ),
      DataCell(
        DashboardStatusPill(
          account.status,
          color: account.status == 'ACTIVE'
              ? AppTheme.dashboardGreen
              : AppTheme.dashboardRed,
        ),
      ),
      DataCell(Text(account.scope)),
      DataCell(
        Tooltip(
          message: account.createdAt.toUtc().toIso8601String(),
          child: Text(_date(account.createdAt)),
        ),
      ),
      DataCell(
        IconButton(
          tooltip: 'Editar cuenta',
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppTheme.dashboardBlue,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.dashboardBlue.withValues(alpha: .08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          onPressed: () => _linkAccount(account),
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
