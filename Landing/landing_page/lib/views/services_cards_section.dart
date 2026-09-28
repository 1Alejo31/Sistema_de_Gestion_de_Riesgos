import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ServicesCardsSection extends StatefulWidget {
  const ServicesCardsSection({super.key});

  @override
  State<ServicesCardsSection> createState() => _ServicesCardsSectionState();
}

class _ServicesCardsSectionState extends State<ServicesCardsSection> with TickerProviderStateMixin {
  int? _hoveredIndex;
  late List<AnimationController> _pulseControllers;

  @override
  void initState() {
    super.initState();
    _pulseControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 200)),
        vsync: this,
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (var controller in _pulseControllers) {
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.white,
            AppTheme.backgroundLight,
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: isDesktop ? AppTheme.spacingXXL * 1.5 : AppTheme.spacingXL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppTheme.primaryNavy, AppTheme.secondaryBlue],
                ).createShader(bounds),
                child: Text(
                  'Servicios Especializados',
                  style: AppTheme.heading1.copyWith(fontSize: 42),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Soluciones integrales con tecnología de punta',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              isDesktop ? _buildDesktopCards() : _buildMobileCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCards() {
    return Row(
      children: [
        Expanded(child: _buildServiceCard(0, 'Evaluación de Riesgos', 'Identificación inteligente con IA', Icons.health_and_safety, AppTheme.successGreen)),
        const SizedBox(width: AppTheme.spacingL),
        Expanded(child: _buildServiceCard(1, 'Capacitación Digital', 'Formación continua y efectiva', Icons.school, AppTheme.secondaryBlue)),
        const SizedBox(width: AppTheme.spacingL),
        Expanded(child: _buildServiceCard(2, 'Monitoreo 24/7', 'Vigilancia en tiempo real', Icons.monitor_heart, AppTheme.accentOrange)),
      ],
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: [
        _buildServiceCard(0, 'Evaluación de Riesgos', 'Identificación inteligente con IA', Icons.health_and_safety, AppTheme.successGreen),
        const SizedBox(height: AppTheme.spacingL),
        _buildServiceCard(1, 'Capacitación Digital', 'Formación continua y efectiva', Icons.school, AppTheme.secondaryBlue),
        const SizedBox(height: AppTheme.spacingL),
        _buildServiceCard(2, 'Monitoreo 24/7', 'Vigilancia en tiempo real', Icons.monitor_heart, AppTheme.accentOrange),
      ],
    );
  }

  Widget _buildServiceCard(int index, String title, String subtitle, IconData icon, Color color) {
    final isHovered = _hoveredIndex == index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, isHovered ? -16.0 : 0.0),
          child: Container(
            constraints: BoxConstraints(
              minHeight: 340,
              maxHeight: 400,
            ),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isHovered ? color : color.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isHovered ? 0.3 : 0.12),
                  blurRadius: isHovered ? 40 : 20,
                  offset: Offset(0, isHovered ? 16 : 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ilustración grande con gradiente circular
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo de fondo animado
                    AnimatedBuilder(
                      animation: _pulseControllers[index],
                      builder: (context, child) {
                        return Container(
                          width: 120 + (_pulseControllers[index].value * 15),
                          height: 120 + (_pulseControllers[index].value * 15),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.05),
                                color.withOpacity(0),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Círculo principal del icono
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(isHovered ? 0.25 : 0.15),
                            color.withOpacity(isHovered ? 0.15 : 0.08),
                          ],
                        ),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        icon,
                        size: 56,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTheme.heading3.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: AppTheme.bodyRegular.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isHovered
                        ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                        : null,
                    color: isHovered ? null : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver más',
                        style: AppTheme.bodySmall.copyWith(
                          color: isHovered ? AppTheme.white : color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        color: isHovered ? AppTheme.white : color,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
