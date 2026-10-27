import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class OperationSuccessDialog extends StatelessWidget {
  const OperationSuccessDialog({
    super.key,
    required this.title,
    required this.description,
    required this.detail,
    this.iconKey,
    this.detailKey,
    this.confirmKey = const Key('operation_success_confirm'),
  });

  final String title;
  final String description;
  final String detail;
  final Key? iconKey;
  final Key? detailKey;
  final Key confirmKey;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    contentPadding: const EdgeInsets.fromLTRB(28, 30, 28, 12),
    actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppTheme.dashboardGreen.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            key: iconKey,
            color: AppTheme.dashboardGreen,
            size: 52,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.dashboardBlueDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.dashboardMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.dashboardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dashboardLine),
          ),
          child: Text(
            detail,
            key: detailKey,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.dashboardBlueDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
    actions: [
      SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton(
          key: confirmKey,
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.dashboardBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Entendido'),
        ),
      ),
    ],
  );
}
