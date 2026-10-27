import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/section_content.dart';
import '../widgets/widget_factory.dart';

class FeaturesSection extends StatelessWidget {
  final FeaturesContent content;

  const FeaturesSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return WidgetFactory.createSectionContainer(
      backgroundColor: AppTheme.white,
      child: WidgetFactory.createContentWrapper(
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              content.title,
              style: AppTheme.heading1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              content.description,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textDark.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            _buildStepsTimeline(content.steps),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsTimeline(List<WorkflowStep> steps) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Column(
          children: [
            WidgetFactory.createStepCard(
              number: step.number,
              title: step.title,
              description: step.description,
              imagePath: step.imagePath,
            ),
            if (!isLast) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingM,
                ),
                child: _buildConnector(),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 3,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.secondaryBlue.withValues(alpha: 0.3),
            AppTheme.successGreen.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
