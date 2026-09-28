import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';
import '../models/section_content.dart';
import '../widgets/widget_factory.dart';
import '../controllers/page_controller.dart';

class HeroSection extends StatefulWidget {
  final HeroContent content;
  final LandingPageController controller;

  const HeroSection({
    super.key,
    required this.content,
    required this.controller,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: isDesktop ? 700 : 900,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD5E8F7),
            Color(0xFFE8F4FD),
            AppTheme.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Círculos de fondo decorativos
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryBlue.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightBlue.withOpacity(0.08),
              ),
            ),
          ),

          // Contenido principal
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingXXL,
                ),
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: _buildTextContent(),
        ),
        const SizedBox(width: AppTheme.spacingXXL),
        Expanded(
          flex: 5,
          child: _buildVisualContent(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVisualContent(),
        const SizedBox(height: AppTheme.spacingXL),
        _buildTextContent(),
      ],
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge "Fast Treatment"
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(-30 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryBlue.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.health_and_safety, color: AppTheme.secondaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Gestión Preventiva',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),

        // Título principal estilo "QUICK SMART MEDIC"
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(-30 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'GESTIÓN',
                    style: AppTheme.heroTitle.copyWith(
                      fontSize: 68,
                      color: AppTheme.primaryNavy,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.verified,
                    color: AppTheme.secondaryBlue,
                    size: 40,
                  ),
                ],
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                ).createShader(bounds),
                child: Text(
                  'INTELIGENTE',
                  style: AppTheme.heroTitle.copyWith(
                    fontSize: 68,
                    color: AppTheme.white,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              Text(
                'SST',
                style: AppTheme.heroTitle.copyWith(
                  fontSize: 68,
                  color: AppTheme.primaryNavy,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),

        // Descripción
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(-30 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: Text(
            widget.content.subtitle,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textMuted,
              height: 1.6,
              fontSize: 16,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXL),

        // Botón CTA
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [AppTheme.primaryNavy, AppTheme.secondaryBlue],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => widget.controller.scrollToSection('contacto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppTheme.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explorar Más',
                    style: AppTheme.buttonText.copyWith(
                      fontSize: 16,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualContent() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: child,
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Círculo de fondo grande con efecto glow
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.secondaryBlue.withOpacity(0.15 + (_pulseController.value * 0.1)),
                        AppTheme.lightBlue.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Imagen SST - Diseño como la referencia (difuminada abajo)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo de fondo decorativo grande
                Positioned(
                  top: 30,
                  right: -50,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.lightBlue.withOpacity(0.2),
                          AppTheme.veryLightBlue.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Imagen principal - forma como la referencia
                Container(
                  width: 350,
                  height: 420,
                  child: Stack(
                    children: [
                      // Contenedor con forma especial
                      ClipPath(
                        clipper: HeroImageClipper(),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryBlue.withOpacity(0.2),
                                blurRadius: 60,
                                offset: const Offset(0, 25),
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Imagen profesional SST con chaleco azul
                              Image.asset(
                                'assets/images/profesional_sst_hero.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.secondaryBlue.withOpacity(0.8),
                                          AppTheme.lightBlue.withOpacity(0.6),
                                          AppTheme.veryLightBlue.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.health_and_safety,
                                            size: 120,
                                            color: AppTheme.white.withOpacity(0.9),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'SST',
                                            style: TextStyle(
                                              color: AppTheme.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Gradiente overlay - más transparente arriba, más opaco abajo
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      AppTheme.veryLightBlue.withOpacity(0.3),
                                      AppTheme.veryLightBlue.withOpacity(0.6),
                                    ],
                                    stops: [0.0, 0.5, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card flotante "490" (top right)
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Positioned(
                top: 20 + (_floatingController.value * 15),
                right: 20,
                child: _buildStatsCard(
                  number: '98%',
                  label: 'Precisión',
                  icon: Icons.trending_up,
                  color: AppTheme.successGreen,
                ),
              );
            },
          ),

          // Card flotante "6700" (right middle)
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Positioned(
                right: 0,
                top: 180 + (_floatingController.value * -12),
                child: _buildStatsCard(
                  number: '3.5K',
                  label: 'Empresas',
                  icon: Icons.business,
                  color: AppTheme.secondaryBlue,
                ),
              );
            },
          ),

          // Card flotante "22 Years" (bottom left)
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Positioned(
                bottom: 40 + (_floatingController.value * 10),
                left: 10,
                child: _buildInfoCard(
                  icon: Icons.verified_user,
                  title: '100%',
                  subtitle: 'Cumplimiento',
                ),
              );
            },
          ),

          // Gráfico flotante estilo "pulmones" - Icono de casco de seguridad
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Positioned(
                top: 60 + (_floatingController.value * 20),
                left: -20,
                child: AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateController.value * 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentOrange.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.health_and_safety,
                          size: 60,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Gráfico flotante - Monitor de salud
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Positioned(
                bottom: 100 + (_floatingController.value * -15),
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.monitor_heart,
                    size: 55,
                    color: AppTheme.accentPurple,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String number,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            number,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryNavy,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Clipper personalizado para forma similar a la referencia
// Redondeada arriba, difuminada/cortada abajo
class HeroImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    // Comenzar desde arriba izquierda con curva
    path.moveTo(size.width * 0.15, 0);

    // Curva superior izquierda
    path.quadraticBezierTo(
      0, 0,
      0, size.height * 0.15,
    );

    // Lado izquierdo con ligera curva
    path.lineTo(0, size.height * 0.7);

    // Curva inferior izquierda (más suave)
    path.quadraticBezierTo(
      0, size.height * 0.85,
      size.width * 0.1, size.height * 0.9,
    );

    // Parte inferior - línea inclinada suave (difuminada)
    path.lineTo(size.width * 0.9, size.height);

    // Curva inferior derecha
    path.quadraticBezierTo(
      size.width, size.height * 0.95,
      size.width, size.height * 0.8,
    );

    // Lado derecho
    path.lineTo(size.width, size.height * 0.15);

    // Curva superior derecha
    path.quadraticBezierTo(
      size.width, 0,
      size.width * 0.85, 0,
    );

    // Cerrar el path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
