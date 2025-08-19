import 'package:flutter/material.dart';

class ShareQRPage extends StatelessWidget {
  const ShareQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Share QR Code",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF15d1cb),
                  borderRadius: BorderRadius.circular(50),
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
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 55, 235, 235),
                            Color(0xFF25b5e6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        size: 120,
                        color: Colors.white,
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

              // Copy Code Button
              ElevatedButton.icon(
                onPressed: () {
                  // Copy to clipboard (implement later)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Code copied to clipboard")),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text(
                  "Copy Code",
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
          ),
        ),
      ),
    );
  }
}
