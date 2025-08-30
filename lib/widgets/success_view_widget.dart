import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuccessViewWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  const SuccessViewWidget({
    super.key,
    this.title = 'Connected!',
    this.subtitle = 'Your chat session is now active',
    this.buttonText = 'Start Chatting',
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success checkmark with animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryFixedDim,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 50, color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: Icon(Icons.chat, color: colorScheme.onPrimary),
              label: Text(
                buttonText,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed:
                  onButtonPressed ??
                  () {
                    context.pop();
                    // Navigate to chat or home screen
                    // You can add navigation logic here based on your routing setup
                  },
            ),
          ],
        ),
      ),
    );
  }
}
