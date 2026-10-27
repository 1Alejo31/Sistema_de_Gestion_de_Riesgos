import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Factory pattern for creating reusable widgets
/// Ensures consistent UI components across the application
class WidgetFactory {
  /// Create a primary CTA button
  static Widget createPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isFullWidth = false,
  }) {
    final button = ElevatedButton(onPressed: onPressed, child: Text(text));

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  /// Create a secondary outline button
  static Widget createSecondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(onPressed: onPressed, child: Text(text));
  }

  /// Create a section container with consistent padding
  static Widget createSectionContainer({
    required Widget child,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      color: backgroundColor ?? AppTheme.white,
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingXXL,
          ),
      child: child,
    );
  }

  /// Create a constrained content wrapper for max-width layouts
  static Widget createContentWrapper({
    required Widget child,
    double maxWidth = 1200,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Create a feature card with icon, title, and description
  static Widget createFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    bool isPrimary = false,
  }) {
    return Container(
      height: null, // Allow dynamic height
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border.all(
          color: isPrimary
              ? AppTheme.secondaryBlue.withValues(alpha: 0.3)
              : AppTheme.textDark.withValues(alpha: 0.1),
          width: isPrimary ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: isPrimary ? AppTheme.cardShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppTheme.secondaryBlue.withValues(alpha: 0.1)
                  : AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(
              icon,
              size: 32,
              color: isPrimary ? AppTheme.secondaryBlue : AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            title,
            style: AppTheme.heading3,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Flexible(
            child: Text(
              description,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textDark.withValues(alpha: 0.8),
                height: 1.7,
              ),
              maxLines: null, // Allow all lines
            ),
          ),
        ],
      ),
    );
  }

  /// Create a step card for workflow visualization
  static Widget createStepCard({
    required int number,
    required String title,
    required String description,
    String? imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlue,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.heading3),
                const SizedBox(height: AppTheme.spacingS),
                Text(description, style: AppTheme.bodyRegular),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Create a form field with consistent styling
  static Widget createFormField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyRegular.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTheme.bodyRegular,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: AppTheme.textDark.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: AppTheme.textDark.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: const BorderSide(
                color: AppTheme.secondaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingS,
            ),
          ),
        ),
      ],
    );
  }
}
