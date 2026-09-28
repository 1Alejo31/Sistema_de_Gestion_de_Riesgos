import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/section_content.dart';

class ProductsSection extends StatefulWidget {
  final ProductsContent content;

  const ProductsSection({
    super.key,
    required this.content,
  });

  @override
  State<ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<ProductsSection> {
  int? _hoveredIndex;

  // Imágenes placeholder - Reemplaza con tus imágenes reales
  final List<String> _featureImages = [
    'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&h=600&fit=crop', // Dashboard/Analytics
    'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=800&h=600&fit=crop', // Comunicación/Email
    'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&h=600&fit=crop', // Integraciones/Tech
    'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop', // IA/Datos
    'https://images.unsplash.com/photo-1551434678-e076c223a692?w=800&h=600&fit=crop', // Dashboard ejecutivo
    'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&h=600&fit=crop', // Gestión personas
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      width: double.infinity,
      color: AppTheme.white,
      padding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: isDesktop ? AppTheme.spacingXXL * 2 : AppTheme.spacingXL,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            child: Column(
              children: [
                Text(
                  'Capacidades CRM',
                  style: AppTheme.heading1.copyWith(
                    fontSize: isDesktop ? 56 : 40,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingM),
                SizedBox(
                  width: 700,
                  child: Text(
                    'Una plataforma completa para gestionar la seguridad y salud de tu equipo',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXXL),

          // Features con imágenes
          ...widget.content.features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final isEven = index % 2 == 0;

            return _buildFeatureRow(
              title: feature.title,
              description: feature.description,
              imageUrl: _featureImages[index % _featureImages.length],
              imageOnRight: isEven,
              index: index,
              isDesktop: isDesktop,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required String title,
    required String description,
    required String imageUrl,
    required bool imageOnRight,
    required int index,
    required bool isDesktop,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
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
      child: Container(
        margin: EdgeInsets.only(bottom: isDesktop ? AppTheme.spacingXXL * 1.5 : AppTheme.spacingXL),
        child: isDesktop
            ? _buildDesktopFeatureRow(title, description, imageUrl, imageOnRight, index)
            : _buildMobileFeatureRow(title, description, imageUrl, index),
      ),
    );
  }

  Widget _buildDesktopFeatureRow(String title, String description, String imageUrl, bool imageOnRight, int index) {
    final content = _buildContentColumn(title, description, index);
    final image = _buildImageContainer(imageUrl, index);

    return Container(
      constraints: const BoxConstraints(maxWidth: 1400),
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXXL),
      child: Row(
        children: imageOnRight
            ? [
                Expanded(flex: 5, child: content),
                const SizedBox(width: AppTheme.spacingXXL * 2),
                Expanded(flex: 5, child: image),
              ]
            : [
                Expanded(flex: 5, child: image),
                const SizedBox(width: AppTheme.spacingXXL * 2),
                Expanded(flex: 5, child: content),
              ],
      ),
    );
  }

  Widget _buildMobileFeatureRow(String title, String description, String imageUrl, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        children: [
          _buildImageContainer(imageUrl, index),
          const SizedBox(height: AppTheme.spacingL),
          _buildContentColumn(title, description, index),
        ],
      ),
    );
  }

  Widget _buildContentColumn(String title, String description, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTheme.heading2.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryNavy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          description,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textMuted,
            fontSize: 18,
            height: 1.7,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.secondaryBlue,
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Conocer más',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.secondaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageContainer(String imageUrl, int index) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_hoveredIndex == index ? 1.02 : 1.0),
        child: Container(
          height: isDesktop ? 400 : 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryNavy.withOpacity(_hoveredIndex == index ? 0.15 : 0.08),
                blurRadius: _hoveredIndex == index ? 40 : 24,
                offset: Offset(0, _hoveredIndex == index ? 16 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagen de fondo
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.secondaryBlue.withOpacity(0.8),
                            AppTheme.lightBlue.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: AppTheme.white.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.backgroundLight,
                            AppTheme.veryLightBlue,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Overlay gradiente sutil
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryNavy.withOpacity(0.1),
                      ],
                    ),
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
