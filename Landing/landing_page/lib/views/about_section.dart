import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/section_content.dart';

class AboutSection extends StatelessWidget {
  final AboutContent content;

  const AboutSection({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      width: double.infinity,
      color: AppTheme.backgroundLight,
      padding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: isDesktop ? AppTheme.spacingXXL * 2 : AppTheme.spacingXXL,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            child: Column(
              children: [
                Text(
                  content.title,
                  style: AppTheme.heading1.copyWith(
                    fontSize: isDesktop ? 52 : 38,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXL),
              ],
            ),
          ),

          // Content blocks con imágenes
          _buildContentWithImage(
            title: 'Nuestra Misión',
            content: content.mission,
            imageUrl: 'assets/images/agente_inteligente_mision.png',
            imageOnRight: true,
            isDesktop: isDesktop,
            isAsset: true,
          ),
          SizedBox(height: isDesktop ? AppTheme.spacingXXL * 1.5 : AppTheme.spacingXL),

          _buildContentWithImage(
            title: 'El Desafío',
            content: content.problem,
            imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&h=600&fit=crop',
            imageOnRight: false,
            isDesktop: isDesktop,
            isAsset: false,
          ),
          SizedBox(height: isDesktop ? AppTheme.spacingXXL * 1.5 : AppTheme.spacingXL),

          _buildContentWithImage(
            title: 'Nuestra Solución',
            content: content.approach,
            imageUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=1200&h=600&fit=crop',
            imageOnRight: true,
            isDesktop: isDesktop,
            isAsset: false,
          ),
        ],
      ),
    );
  }

  Widget _buildContentWithImage({
    required String title,
    required String content,
    required String imageUrl,
    required bool imageOnRight,
    required bool isDesktop,
    required bool isAsset,
  }) {
    final textContent = Expanded(
      flex: 5,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? AppTheme.spacingXXL : AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTheme.heading2.copyWith(
                fontSize: isDesktop ? 38 : 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              content,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textMuted,
                fontSize: isDesktop ? 18 : 16,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );

    final imageContent = Expanded(
      flex: 5,
      child: Container(
        height: isDesktop ? 400 : 250,
        margin: EdgeInsets.symmetric(horizontal: isDesktop ? AppTheme.spacingXL : AppTheme.spacingL),
        decoration: BoxDecoration(
          color: isAsset ? AppTheme.veryLightBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNavy.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: isAsset
              ? Image.asset(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.secondaryBlue.withOpacity(0.6),
                            AppTheme.lightBlue.withOpacity(0.4),
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
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.secondaryBlue.withOpacity(0.6),
                            AppTheme.lightBlue.withOpacity(0.4),
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
                ),
        ),
      ),
    );

    if (!isDesktop) {
      return Column(
        children: [
          SizedBox(
            height: 250,
            child: imageContent,
          ),
          textContent,
        ],
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 1400),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: imageOnRight
            ? [textContent, imageContent]
            : [imageContent, textContent],
      ),
    );
  }
}
