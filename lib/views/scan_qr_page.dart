import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/scan_qr_view_model.dart';
import '../widgets/success_view_widget.dart';
import '../widgets/waiting_view_widget.dart';
import '../widgets/loading_view_widget.dart';
import '../widgets/error_view_widget.dart';
import '../widgets/nickname_dialog.dart';

class ScanQrPage extends StatelessWidget {
  const ScanQrPage({super.key, required this.viewModel});

  final ScanQRViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () {
            context.pop();
          },
        ),
        centerTitle: true,
        title: Text(
          "Scan QR Code",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          // Show error state
          if (viewModel.errorMessage != null) {
            return ErrorViewWidget(
              errorMessage: viewModel.errorMessage ?? "An error occurred",
              onRetry: () {
                viewModel.clearError();
                // Re-initialize user which will also initialize scanner
                viewModel.initializeUser();
              },
            );
          }

          // Show success state when session is activated
          if (!viewModel.isWaitingForActivation &&
              viewModel.chatId != null &&
              !viewModel.isLoading &&
              !viewModel.isCreating) {
            return SuccessViewWidget(
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
                    context.go('/chat/${viewModel.chatId}');
                  }
                }
              },
            );
          }

          // Show waiting for activation state
          if (viewModel.isWaitingForActivation) {
            return const WaitingViewWidget(
              title: 'Waiting for Confirmation',
              subtitle: 'Please wait while your friend confirms the connection',
              infoText: 'Your connection request has been sent',
            );
          }

          // Show loading state
          if (viewModel.isLoading || viewModel.isCreating) {
            String message = "Initializing...";
            if (viewModel.isCreating) {
              message = "Creating session...";
            }
            return LoadingViewWidget(message: message);
          }

          // Default scanner view
          return _buildScannerView(context);
        },
      ),
    );
  }

  Widget _buildScannerView(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: viewModel.scannerController,
          onDetect: viewModel.onDetect,
        ),
        // Overlay for scan area
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: cs.primary, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        // Instructions
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Point your camera at your friend's QR code to connect",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
