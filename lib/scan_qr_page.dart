import 'package:flutter/material.dart';

class ScanQRPage extends StatelessWidget {
  const ScanQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          "Scan QR Code",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR scanner mock box with layered padding and borders
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFC9F2F0),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 143, 200, 208),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9F2F0),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      251,
                      251,
                      251,
                    ), // white background
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 154, 224, 221),
                        width: 2,
                      ), // gray border
                      borderRadius: BorderRadius.circular(30),
                    ),
                    height: 170,
                    width: 170,
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 60,
                        color: Color.fromARGB(255, 23, 184, 168),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Point your camera at your friend's QR code to \nconnect",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),

            const SizedBox(height: 30),

            // Start Scanning button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text(
                "Start Scanning",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                // Navigate to Home Page
                Navigator.pushReplacementNamed(context, "/home");
              },
            ),
          ],
        ),
      ),
    );
  }
}
