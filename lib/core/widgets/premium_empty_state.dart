import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String imageAsset;
  final Widget? actionButton;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.imageAsset,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.inbox,
                  size: 120,
                  color: AppColors.border,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 32),
              actionButton!,
            ]
          ],
        ),
      ),
    );
  }
}
