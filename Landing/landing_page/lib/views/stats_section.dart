import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1500 + (index * 200)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    Future.delayed(const Duration(milliseconds: 300), () {
      for (var controller in _controllers) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryNavy,
            AppTheme.primaryNavy.withBlue(100),
            AppTheme.secondaryBlue.withOpacity(0.8),
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: isDesktop ? AppTheme.spacingXXL * 2 : AppTheme.spacingXXL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Resultados que Transforman',
                style: AppTheme.heading1.copyWith(
                  color: AppTheme.white,
                  fontSize: 42,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Impacto medible en organizaciones que confían en nuestra plataforma',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              isDesktop ? _buildDesktopStats() : _buildMobileStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAnimatedStatItem(0, '95%', 'Reducción en tiempo\nadministrativo', Icons.trending_down),
        _buildAnimatedStatItem(1, '100%', 'Cumplimiento normativo\ngarantizado', Icons.verified_user),
        _buildAnimatedStatItem(2, '70%', 'Menos incidentes\nreportados', Icons.security),
        _buildAnimatedStatItem(3, '24/7', 'Monitoreo continuo\ninteligente', Icons.auto_awesome),
      ],
    );
  }

  Widget _buildMobileStats() {
    return Column(
      children: [
        _buildAnimatedStatItem(0, '95%', 'Reducción en tiempo\nadministrativo', Icons.trending_down),
        const SizedBox(height: AppTheme.spacingXL),
        _buildAnimatedStatItem(1, '100%', 'Cumplimiento normativo\ngarantizado', Icons.verified_user),
        const SizedBox(height: AppTheme.spacingXL),
        _buildAnimatedStatItem(2, '70%', 'Menos incidentes\nreportados', Icons.security),
        const SizedBox(height: AppTheme.spacingXL),
        _buildAnimatedStatItem(3, '24/7', 'Monitoreo continuo\ninteligente', Icons.auto_awesome),
      ],
    );
  }

  Widget _buildAnimatedStatItem(int index, String number, String label, IconData icon) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Opacity(
          opacity: _animations[index].value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * _animations[index].value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: AppTheme.white.withOpacity(0.9),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppTheme.white,
                  AppTheme.lightBlue.withOpacity(0.8),
                ],
              ).createShader(bounds),
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.white,
                  height: 1.0,
                  letterSpacing: -2.5,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              label,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
