import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../providers/organizations_providers.dart';

Future<void> showOrganizationPicker(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _OrganizationPicker(),
);

class OrganizationSelector extends ConsumerWidget {
  const OrganizationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);
    final selected = ref.watch(selectedOrganizationProvider);
    final count = organizations.asData?.value.length;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: AppTheme.dashboardLine),
      ),
      child: InkWell(
        key: const Key('organization_selector'),
        borderRadius: BorderRadius.circular(13),
        onTap: () => showOrganizationPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              const Icon(
                Icons.apartment,
                color: AppTheme.dashboardBlue,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected?.legalName ?? 'Seleccionar empresa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.dashboardBlueDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      organizations.isLoading
                          ? 'Cargando empresas…'
                          : organizations.hasError
                          ? 'No se pudo cargar · reintentar'
                          : '$count ${count == 1 ? 'empresa' : 'empresas'}',
                      style: const TextStyle(
                        color: AppTheme.dashboardMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.unfold_more,
                color: AppTheme.dashboardBlue,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationPicker extends ConsumerStatefulWidget {
  const _OrganizationPicker();

  @override
  ConsumerState<_OrganizationPicker> createState() =>
      _OrganizationPickerState();
}

class _OrganizationPickerState extends ConsumerState<_OrganizationPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);
    final selectedId = ref.watch(selectedOrganizationIdProvider);
    return AlertDialog(
      key: const Key('organization_picker'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Seleccionar empresa',
              style: TextStyle(
                color: AppTheme.dashboardBlueDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar selector',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.dashboardMuted),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: (MediaQuery.sizeOf(context).height * .55).clamp(180.0, 420.0),
        child: Column(
          children: [
            TextField(
              key: const Key('organization_picker_search'),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              style: const TextStyle(color: AppTheme.dashboardBlueDark),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o NIT…',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.dashboardBlue,
                ),
                filled: true,
                fillColor: AppTheme.dashboardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dashboardLine),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: organizations.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No se pudo cargar el listado de empresas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.dashboardMuted),
                      ),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(organizationsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  final filtered =
                      items
                          .where(
                            (item) => '${item.legalName} ${item.legalId}'
                                .toLowerCase()
                                .contains(_query),
                          )
                          .toList()
                        ..sort(
                          (a, b) => a.legalName.toLowerCase().compareTo(
                            b.legalName.toLowerCase(),
                          ),
                        );
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        items.isEmpty
                            ? 'No tienes empresas disponibles.'
                            : 'No hay empresas que coincidan con la búsqueda.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.dashboardMuted),
                      ),
                    );
                  }
                  return Material(
                    color: Colors.transparent,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) =>
                          const Divider(color: AppTheme.dashboardLine),
                      itemBuilder: (context, index) {
                        final organization = filtered[index];
                        final selected = organization.id == selectedId;
                        return ListTile(
                          key: ValueKey(
                            'select_organization_${organization.id}',
                          ),
                          selected: selected,
                          selectedTileColor: AppTheme.dashboardBlue.withValues(
                            alpha: .08,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: const Icon(
                            Icons.business_outlined,
                            color: AppTheme.dashboardBlue,
                          ),
                          title: Text(
                            organization.legalName,
                            style: const TextStyle(
                              color: AppTheme.dashboardBlueDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'NIT: ${organization.legalId}',
                            style: const TextStyle(
                              color: AppTheme.dashboardMuted,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.dashboardGreen,
                                )
                              : null,
                          onTap: () {
                            ref
                                .read(selectedOrganizationIdProvider.notifier)
                                .select(organization.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
