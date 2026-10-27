import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Shared advisor artwork and message for the desktop panel and mobile drawer.
class DashboardAssistantPreview extends StatelessWidget {
  const DashboardAssistantPreview({super.key});

  static const _title = 'Detecté 3 acciones prioritarias para este mes.';
  static const _description =
      'Recomendaciones basadas en el análisis de tus datos de SST.';
  static const _titleStyle = TextStyle(
    color: AppTheme.dashboardBlueDark,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const _descriptionStyle = TextStyle(
    color: AppTheme.dashboardMuted,
    fontSize: 12,
    height: 1.35,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final textScaler = MediaQuery.textScalerOf(context);
      final stacked = textScaler.scale(14) > 18;
      final bubbleWidth = stacked ? width - 24 : width * .58;
      final imageSize = width * .82;

      double textHeight(String text, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
        )..layout(maxWidth: bubbleWidth - 28);
        final height = painter.height;
        painter.dispose();
        return height;
      }

      final bubbleHeight =
          textHeight(_title, _titleStyle) +
          textHeight(_description, _descriptionStyle) +
          36;
      // Keep the presenting hand below the message, including larger text.
      final height = stacked
          ? bubbleHeight + imageSize + 24
          : math.max(imageSize + 18, bubbleHeight + imageSize * .44);

      return SizedBox(
        height: height,
        child: ClipRect(
          child: CustomPaint(
            painter: const _AdvisorBackdropPainter(),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: -4,
                  width: imageSize,
                  height: imageSize,
                  child: Image.asset(
                    'assets/images/dashboard_advisor.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    excludeFromSemantics: true,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: stacked ? 12 : 4,
                  width: bubbleWidth,
                  child: CustomPaint(
                    painter: const _SpeechTailPainter(),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title, style: _titleStyle),
                          SizedBox(height: 8),
                          Text(_description, style: _descriptionStyle),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SpeechTailPainter extends CustomPainter {
  const _SpeechTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width - 42, size.height - 1)
      ..lineTo(size.width - 24, size.height + 12)
      ..lineTo(size.width - 27, size.height - 1)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SpeechTailPainter oldDelegate) => false;
}

class _AdvisorBackdropPainter extends CustomPainter {
  const _AdvisorBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final wave = Path()
      ..moveTo(0, height * .64)
      ..cubicTo(
        width * .3,
        height * .42,
        width * .52,
        height,
        width,
        height * .7,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0x446BC1F8));
    final foreground = Path()
      ..moveTo(0, height * .94)
      ..cubicTo(
        width * .32,
        height * .35,
        width * .6,
        height * .75,
        width,
        height,
      )
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(foreground, Paint()..color = const Color(0x55FFFFFF));
  }

  @override
  bool shouldRepaint(_AdvisorBackdropPainter oldDelegate) => false;
}
