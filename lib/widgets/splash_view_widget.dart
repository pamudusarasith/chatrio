import 'package:flutter/material.dart';

/// A simple splash screen shown during app initialization.
class SplashViewWidget extends StatelessWidget {
  const SplashViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App logo
          Image.asset('assets/logo.png', height: 96),
          const SizedBox(height: 16),
          // App name
          Text(
            'Chatrio',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          // Subtle progress indicator without extra text
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
