import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../viewmodels/generate_qr_view_model.dart';
import '../widgets/success_view_widget.dart';
import '../widgets/loading_view_widget.dart';
import '../widgets/error_view_widget.dart';

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
              if (viewModel.isSessionActive && viewModel.joinedUserId != null) {
                return const SuccessViewWidget(
                  title: 'Someone Connected!',
                  subtitle: 'Your chat session is now active',
                  buttonText: 'Start Chatting',
                );
              }

              if (!viewModel.isQRGenerated ||
                  viewModel.currentUserId == null ||
                  viewModel.currentSessionId == null) {
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
                      color: const Color(0xFF15d1cb),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 157, 226, 223),
                          blurRadius: 18,
                          spreadRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 247, 248, 250),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
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

                  const Text(
                    "Ask your friend to scan this QR code",
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 30),

                  // Regenerate Session Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      await viewModel.regenerateSessionId();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("New session generated"),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      "New Session",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19c8d1),
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
