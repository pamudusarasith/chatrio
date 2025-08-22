import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({super.key});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  final MobileScannerController controller = MobileScannerController();

  bool _scanned = false;
  String? _scanResult;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      setState(() {
        _scanned = true;
        _scanResult = barcode.rawValue;
      });
      // You can handle navigation or logic here
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Scan QR Code",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          // Overlay for scan area
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyan, width: 4),
                borderRadius: BorderRadius.circular(24),
                // color: Colors.black,
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Colors.cyan,
                  size: 60,
                ),
              ),
            ),
          ),
          // Instructions and button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "Point your camera at your friend's QR code to connect",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    "Restart Scanning",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _scanned = false;
                      _scanResult = null;
                    });
                  },
                ),
                if (_scanResult != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Scanned: $_scanResult",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
