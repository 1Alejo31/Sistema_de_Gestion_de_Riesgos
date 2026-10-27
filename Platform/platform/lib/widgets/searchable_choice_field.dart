import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class SearchChoice {
  const SearchChoice(this.id, this.label, [this.detail = '']);
  final String id;
  final String label;
  final String detail;
}

class SearchableChoiceField extends StatelessWidget {
  const SearchableChoiceField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.options,
    required this.onSelected,
    this.value,
    this.enabled = true,
    this.error,
  });
  final String fieldKey;
  final String label;
  final List<SearchChoice> options;
  final String? value;
  final bool enabled;
  final String? error;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = options.where((item) => item.id == value).firstOrNull;
    return InkWell(
      key: Key(fieldKey),
      borderRadius: BorderRadius.circular(12),
      onTap: !enabled
          ? null
          : () async {
              final result = await showDialog<String>(
                context: context,
                builder: (_) => _ChoicePicker(
                  label: label,
                  options: options,
                  selected: value,
                  fieldKey: fieldKey,
                ),
              );
              if (result != null && context.mounted) onSelected(result);
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          errorMaxLines: 2,
          filled: true,
          fillColor: AppTheme.dashboardBackground.withValues(alpha: .35),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.dashboardLine),
          ),
          suffixIcon: const Icon(
            Icons.expand_more,
            color: AppTheme.dashboardBlue,
          ),
        ),
        child: Text(
          selected?.label ?? 'Selecciona una opción',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: enabled
                ? AppTheme.dashboardBlueDark
                : AppTheme.dashboardMuted,
          ),
        ),
      ),
    );
  }
}

class _ChoicePicker extends StatefulWidget {
  const _ChoicePicker({
    required this.label,
    required this.options,
    required this.selected,
    required this.fieldKey,
  });
  final String label;
  final List<SearchChoice> options;
  final String? selected;
  final String fieldKey;
  @override
  State<_ChoicePicker> createState() => _ChoicePickerState();
}

class _ChoicePickerState extends State<_ChoicePicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final items = widget.options
        .where(
          (option) =>
              '${option.label} ${option.detail}'.toLowerCase().contains(_query),
        )
        .toList();
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        widget.label,
        style: const TextStyle(
          color: AppTheme.dashboardBlueDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 480,
        height: (MediaQuery.sizeOf(context).height * .5).clamp(160.0, 360.0),
        child: Column(
          children: [
            TextField(
              key: Key('${widget.fieldKey}_search'),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar…',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('No hay opciones para esta búsqueda.'),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            key: ValueKey('${widget.fieldKey}_${item.id}'),
                            title: Text(
                              item.label,
                              style: const TextStyle(
                                color: AppTheme.dashboardBlueDark,
                              ),
                            ),
                            subtitle: item.detail.isEmpty
                                ? null
                                : Text(item.detail),
                            trailing: item.id == widget.selected
                                ? const Icon(
                                    Icons.check,
                                    color: AppTheme.dashboardGreen,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, item.id),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
