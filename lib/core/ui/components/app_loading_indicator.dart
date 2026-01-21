import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';

/// Indicador de carregamento do design system
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

/// Scaffold com loading do design system
class AppLoadingScaffold extends StatelessWidget {
  const AppLoadingScaffold({
    super.key,
    this.message,
    this.backgroundColor,
  });

  final String? message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoadingIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: AppColors.textSecondaryDark),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
