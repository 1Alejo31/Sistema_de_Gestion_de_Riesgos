import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../controllers/page_controller.dart';

class Navbar extends StatelessWidget {
  final LandingPageController controller;

  const Navbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryBlue.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLogo(),
                if (isDesktop) ...[
                  _buildDesktopMenu(),
                  const SizedBox(width: AppTheme.spacingL),
                  _buildCTAButton(),
                ] else ...[
                  _buildMobileMenuButton(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.psychology, size: 24, color: AppTheme.white),
        ),
        const SizedBox(width: AppTheme.spacingS),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.primaryNavy, AppTheme.secondaryBlue],
          ).createShader(bounds),
          child: Text(
            'SST',
            style: AppTheme.heading3.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'CRM',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.successGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCTAButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => controller.scrollToSection('contacto'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contacto',
              style: AppTheme.bodyRegular.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopMenu() {
    return Row(
      children: [
        _buildNavItem('Inicio', 'inicio'),
        const SizedBox(width: AppTheme.spacingM),
        _buildNavItem('Nosotros', 'nosotros'),
        const SizedBox(width: AppTheme.spacingM),
        _buildNavItem('Productos', 'productos'),
        const SizedBox(width: AppTheme.spacingM),
        _buildNavItem('Contacto', 'contacto'),
        const SizedBox(width: AppTheme.spacingL),
        _buildLoginButton(),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.secondaryBlue, width: 2),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.secondaryBlue,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login, size: 16),
              const SizedBox(width: 6),
              Text(
                'Ingresar',
                style: AppTheme.bodyRegular.copyWith(
                  color: AppTheme.secondaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, String sectionId) {
    final isActive = controller.currentSection == sectionId;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => controller.scrollToSection(sectionId),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.bodyRegular.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.secondaryBlue : AppTheme.textDark,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                height: 3,
                width: 24,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMenuButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        controller.isMobileMenuOpen ? Icons.close : Icons.menu,
        color: AppTheme.primaryNavy,
      ),
      onPressed: () {
        controller.toggleMobileMenu();
        if (controller.isMobileMenuOpen) {
          _showMobileMenu(context);
        }
      },
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMobileMenuItem(context, 'Inicio', 'inicio'),
              _buildMobileMenuItem(context, 'Quiénes Somos', 'nosotros'),
              _buildMobileMenuItem(context, 'Productos', 'productos'),
              _buildMobileMenuItem(
                context,
                'Características',
                'caracteristicas',
              ),
              _buildMobileMenuItem(context, 'Contacto', 'contacto'),
              const SizedBox(height: AppTheme.spacingM),
              const Divider(),
              const SizedBox(height: AppTheme.spacingM),
              // Botón de Login para mobile
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppTheme.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Iniciar Sesión',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => controller.closeMobileMenu());
  }

  Widget _buildMobileMenuItem(
    BuildContext context,
    String label,
    String sectionId,
  ) {
    final isActive = controller.currentSection == sectionId;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        controller.scrollToSection(sectionId);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingS,
          horizontal: AppTheme.spacingM,
        ),
        child: Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.secondaryBlue : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}
