import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'dashboard_assistant_preview.dart';

/// Right-hand AI recommendations panel shared across dashboard pages.
/// Data and actions are injected by the host page, keeping this widget reusable.
class DashboardAssistantPanel extends StatelessWidget {
  const DashboardAssistantPanel({
    super.key,
    required this.scheduled,
    required this.approved,
    required this.onOpenSuggestion,
    required this.onReviewProposals,
  });

  final Set<String> scheduled;
  final Set<String> approved;
  final ValueChanged<String> onOpenSuggestion;
  final VoidCallback onReviewProposals;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(4, 12, 14, 12),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD9EDFF), Color(0xFFF1F8FE)],
      ),
      border: Border.all(color: const Color(0xFFD7EAFB)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: AppTheme.cardShadow,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        primary: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const DashboardAssistantPreview(),
              _suggestions(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(17, 18, 16, 12),
    child: Row(
      children: [
        const Icon(Icons.auto_awesome, color: AppTheme.dashboardBlue, size: 21),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'SST · Asesora IA',
            style: TextStyle(
              color: AppTheme.dashboardBlueDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFDDF9F0),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: AppTheme.dashboardGreen, size: 9),
              SizedBox(width: 6),
              Text(
                'En línea',
                style: TextStyle(
                  color: Color(0xFF008F6B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _suggestions() => Container(
    margin: const EdgeInsets.fromLTRB(9, 0, 9, 9),
    padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .93),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppTheme.dashboardBlue,
              size: 16,
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'Sugerencias de SST',
                style: TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2D8),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.dashboardOrange,
                    size: 13,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Requiere aprobación',
                    style: TextStyle(
                      color: Color(0xFF9A5100),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _suggestion(
          'critical',
          'Intervenir riesgo crítico',
          'Ruido en planta de producción (Bogotá)',
          Icons.warning_rounded,
          AppTheme.dashboardRed,
        ),
        _suggestion(
          'training',
          'Programar capacitación',
          'Trabajo en alturas\n(48 trabajadores)',
          Icons.groups,
          AppTheme.dashboardGreen,
        ),
        _suggestion(
          'document',
          'Actualizar documento',
          'Procedimiento de emergencias',
          Icons.description,
          AppTheme.dashboardBlue,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onReviewProposals,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Revisar propuestas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dashboardBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _suggestion(
    String id,
    String title,
    String detail,
    IconData icon,
    Color color,
  ) => InkWell(
    onTap: () => onOpenSuggestion(id),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDF4FB))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.dashboardBlueDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.dashboardMuted,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                if (scheduled.contains(id) || approved.contains(id))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      approved.contains(id) ? 'Aprobada' : 'Programada',
                      style: const TextStyle(
                        color: AppTheme.dashboardGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            approved.contains(id) ? Icons.check_circle : Icons.chevron_right,
            color: approved.contains(id)
                ? AppTheme.dashboardGreen
                : AppTheme.dashboardBlueDark,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
