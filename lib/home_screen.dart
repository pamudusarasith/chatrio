import 'package:chatrio/chat_list.dart';
import 'package:flutter/material.dart';

import 'share_qr_page.dart';
import 'scan_qr_page.dart';
import 'create_account_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Image.asset(
                  "assets/logo.png", // Fixed asset path
                  height: 70,
                ),
                const SizedBox(height: 15),
                Text(
                  'Chatrio',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF19c8d1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Connect instantly with friends",
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, // Increased from 60 to 100
                    vertical: 20, // Increased from 15 to 40
                  ),
                  // padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(38, 234, 233, 233),
                        spreadRadius: 3, // Fixed from 80 to 3
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      26,
                    ), // Increased from 16 to 26
                    child: Image.asset(
                      "assets/Home-page-image.jpg", // Fixed asset path
                      height: 140,
                      width: 270,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                // My Chats Button
                SizedBox(
                  width: 270,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: const Color(0xFF19c8d1),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      "My Chats",
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatsPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 15),
                // Start New Chat (QR) Button as clickable text
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShareQRPage(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code, color: Colors.black),
                        const SizedBox(width: 8),
                        const Text(
                          "Start New Chat (Generate QR)",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Scan QR to Join Button
                SizedBox(
                  width: 270,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide(color: Colors.teal.shade200),
                      backgroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.filter_center_focus),
                    label: const Text(
                      "Scan QR to Join",
                      style: TextStyle(fontSize: 15, color: Colors.teal),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ScanQRPage()),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // Share QR tip text
                Text(
                  "Share QR codes to connect instantly • No signup required",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),

                const SizedBox(height: 20),

                // Create account link
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAccountPage(),
                        ),
                      );
                    },
                    child: Text(
                      "New user? Create an account",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue, // Changed to link color
                        fontWeight: FontWeight.w500,
                        // decoration: TextDecoration.underline, // Link style
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
