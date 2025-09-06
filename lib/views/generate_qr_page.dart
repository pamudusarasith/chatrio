import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/generate_qr_view_model.dart';
import '../widgets/success_view_widget.dart';
import '../widgets/loading_view_widget.dart';
import '../widgets/error_view_widget.dart';
import '../widgets/nickname_dialog.dart';

class GenerateQRPage extends StatelessWidget {
  const GenerateQRPage({super.key, required this.viewModel});

  final GenerateQRViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Share QR Code",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) {
              return IconButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        await viewModel.generateNewQRCode();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("New session generated"),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.refresh),
                tooltip: 'Generate New Session',
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) {
              final theme = Theme.of(context);
              final cs = theme.colorScheme;
              if (viewModel.isLoading) {
                return const LoadingViewWidget(
                  message: 'Generating QR Code...',
                );
              }

              if (viewModel.errorMessage != null) {
                return ErrorViewWidget(
                  errorMessage: viewModel.errorMessage!,
                  onRetry: () => viewModel.generateNewQRCode(),
                  retryButtonText: 'Try Again',
                );
              }

              // Show success state when session is activated
              if (viewModel.isChatActive && viewModel.joinedUserId != null) {
                return SuccessViewWidget(
                  title: 'Someone Connected!',
                  subtitle: 'Your chat session is now active',
                  buttonText: 'Start Chatting',
                  onButtonPressed: () async {
                    // Show nickname dialog
                    String? nickname = await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const NicknameDialog(),
                    );
                    if (nickname != null) {
                      // Save chat with nickname
                      bool success = await viewModel.startChatting(nickname);
                      if (success && context.mounted) {
                        // Navigate to home or chat list
                        context.go('/chat/${viewModel.currentChatId}');
                      }
                    }
                  },
                );
              }

              if (!viewModel.isQRGenerated ||
                  viewModel.currentUserId == null ||
                  viewModel.currentChatId == null) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('No QR Code generated')],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.12),
                          blurRadius: 18,
                          spreadRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: viewModel.qrCodeData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Text(
                    "Ask your friend to scan this QR code",
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),

                  const SizedBox(height: 30),

                  // Regenerate Session Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      await viewModel.regenerateChatId();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("New session generated"),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.refresh, color: cs.onPrimary),
                    label: Text(
                      "New Session",
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 34,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
