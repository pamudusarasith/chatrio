import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../viewmodels/generate_qr_view_model.dart';

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
                              content: Text("New QR code generated"),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.refresh),
                tooltip: 'Generate New QR Code',
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
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating QR Code...'),
                  ],
                );
              }

              if (viewModel.errorMessage != null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => viewModel.clearError(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                );
              }

              if (!viewModel.isQRGenerated || viewModel.currentUserId == null) {
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
                          data: viewModel.currentUserId!,
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
                  const SizedBox(height: 16),

                  // User ID display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'ID: ${viewModel.currentUserId!.substring(0, 8)}...',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Copy Code Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      await viewModel.copyToClipboard();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("User ID copied to clipboard"),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text(
                      "Copy User ID",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19c8d1),
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
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
