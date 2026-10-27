import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.dashboardPanel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dashboardLine),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.dashboardBlue.withValues(alpha: .045),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class DashboardHeading extends StatelessWidget {
  const DashboardHeading(
    this.title, {
    super.key,
    this.icon,
    this.action,
    this.onAction,
  });

  final String title;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.dashboardBlue, size: 22),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.dashboardBlueDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 15),
            label: Text(action!, style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.dashboardBlue,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    required this.progress,
    required this.footer,
    this.onTap,
  });

  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final double progress;
  final String footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.dashboardBlueDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.dashboardBlueDark,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  change,
                  style: const TextStyle(
                    color: AppTheme.dashboardGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFDDEEFF),
              color: color,
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              footer,
              style: const TextStyle(
                color: AppTheme.dashboardMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardNavTile extends StatelessWidget {
  const DashboardNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.expanded,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool? expanded;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final activeColor = selected
        ? AppTheme.dashboardBlue
        : AppTheme.dashboardBlueDark;
    return Material(
      color: selected ? AppTheme.dashboardBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .2)
                      : const Color(0xFFE4F2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppTheme.dashboardBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : activeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withValues(alpha: .83)
                              : AppTheme.dashboardMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (expanded != null)
                Icon(
                  expanded! ? Icons.keyboard_arrow_up : Icons.chevron_right,
                  color: selected ? Colors.white : AppTheme.dashboardBlueDark,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardStatusPill extends StatelessWidget {
  const DashboardStatusPill(
    this.label, {
    super.key,
    required this.color,
    this.background,
  });
  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background ?? color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class ComplianceTrendChart extends StatelessWidget {
  const ComplianceTrendChart({
    super.key,
    required this.values,
    required this.labels,
    required this.currentLabel,
  });
  final List<double> values;
  final List<String> labels;
  final String currentLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    child: CustomPaint(
      painter: _TrendPainter(values, labels, currentLabel),
      child: const SizedBox.expand(),
    ),
  );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.labels, this.currentLabel);
  final List<double> values;
  final List<String> labels;
  final String currentLabel;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0;
    const right = 8.0;
    const top = 15.0;
    const bottom = 24.0;
    final graph = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final grid = Paint()
      ..color = const Color(0xFFDCEBFA)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = graph.top + graph.height * i / 4;
      canvas.drawLine(Offset(graph.left, y), Offset(graph.right, y), grid);
      _drawText(
        canvas,
        '${100 - i * 10}%',
        Offset(0, y - 7),
        const TextStyle(color: AppTheme.dashboardMuted, fontSize: 9),
      );
    }
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = graph.left + graph.width * i / (values.length - 1);
      final y = graph.bottom - ((values[i] - 60) / 40) * graph.height;
      points.add(Offset(x, y));
      if (i % 2 == 0 || i == values.length - 1) {
        _drawText(
          canvas,
          labels[i],
          Offset(x - 7, size.height - 18),
          const TextStyle(color: AppTheme.dashboardMuted, fontSize: 9),
        );
      }
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final area = Path.from(path)
      ..lineTo(points.last.dx, graph.bottom)
      ..lineTo(points.first.dx, graph.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x553B9AFF), Color(0x003B9AFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(graph),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.dashboardBlue
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = AppTheme.dashboardBlue);
    }
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(points.last.dx - 28, points.last.dy - 32, 48, 23),
      const Radius.circular(7),
    );
    canvas.drawRRect(bubble, Paint()..color = AppTheme.dashboardBlue);
    _drawText(
      canvas,
      currentLabel,
      Offset(bubble.left + 10, bubble.top + 4),
      const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.currentLabel != currentLabel;
}

class RiskDistributionChart extends StatelessWidget {
  const RiskDistributionChart({super.key, this.total = '142'});
  final String total;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 175,
    child: Row(
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: SizedBox(
              width: 148,
              height: 148,
              child: CustomPaint(
                painter: const _DonutPainter(),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total,
                        style: const TextStyle(
                          color: AppTheme.dashboardBlueDark,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'riesgos\ntotales',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.dashboardMuted,
                          fontSize: 12,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RiskLegend(
                color: AppTheme.dashboardRed,
                label: 'Críticos',
                count: '8',
                percent: '6%',
              ),
              _RiskLegend(
                color: AppTheme.dashboardOrange,
                label: 'Altos',
                count: '28',
                percent: '20%',
              ),
              _RiskLegend(
                color: AppTheme.dashboardBlue,
                label: 'Medios',
                count: '66',
                percent: '46%',
              ),
              _RiskLegend(
                color: AppTheme.dashboardGreen,
                label: 'Bajos',
                count: '40',
                percent: '28%',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RiskLegend extends StatelessWidget {
  const _RiskLegend({
    required this.color,
    required this.label,
    required this.count,
    required this.percent,
  });
  final Color color;
  final String label;
  final String count;
  final String percent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.dashboardMuted,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: AppTheme.dashboardBlueDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          percent,
          style: const TextStyle(color: AppTheme.dashboardMuted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    final segments = <(Color, double)>[
      (AppTheme.dashboardGreen, .28),
      (AppTheme.dashboardBlue, .46),
      (AppTheme.dashboardOrange, .20),
      (AppTheme.dashboardRed, .06),
    ];
    var start = -1.5708;
    for (final (color, fraction) in segments) {
      final sweep = fraction * 6.28318 - .025;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.butt,
      );
      start += fraction * 6.28318;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => false;
}
