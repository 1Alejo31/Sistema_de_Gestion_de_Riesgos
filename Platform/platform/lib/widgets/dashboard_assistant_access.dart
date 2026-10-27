import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Compact, animated entry point when the permanent assistant panel is hidden.
class DashboardAssistantLauncher extends StatefulWidget {
  const DashboardAssistantLauncher({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<DashboardAssistantLauncher> createState() =>
      _DashboardAssistantLauncherState();
}

class _DashboardAssistantLauncherState extends State<DashboardAssistantLauncher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _glow.stop();
      _glow.value = 0;
    } else if (!_glow.isAnimating) {
      _glow.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _glow,
    builder: (context, child) {
      final glow = Curves.easeInOut.transform(_glow.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dashboardPurple.withValues(
                alpha: .12 + glow * .13,
              ),
              blurRadius: 18 + glow * 10,
              spreadRadius: glow * 3,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          tooltip: 'Abrir asesora de IA',
          onPressed: widget.onPressed,
          backgroundColor: AppTheme.dashboardBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: Transform.scale(
            scale: 1 + glow * .08,
            child: const Icon(Icons.auto_awesome, size: 23),
          ),
          label: const Text(
            'Asesora IA',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    },
  );
}

/// Used as Scaffold.endDrawer for its slide transition, scrim and back handling.
class DashboardAssistantDrawer extends StatelessWidget {
  const DashboardAssistantDrawer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Drawer(
    width: math.min(400, MediaQuery.sizeOf(context).width),
    backgroundColor: AppTheme.dashboardBackground,
    elevation: 16,
    semanticLabel: 'Panel de la asesora de IA',
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
    ),
    child: SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - progress)),
            child: child,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.dashboardBlue),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tu asistente SST',
                      style: TextStyle(
                        color: AppTheme.dashboardBlueDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar asesora de IA',
                    onPressed: () => Scaffold.of(context).closeEndDrawer(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.dashboardMuted,
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}
