import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chats = [
      {
        "name": "Indumathi",
        "message": "phone ek balapn miniho",
        "time": "1m ago",
        "unread": 0,
        "online": false,
      },
      {
        "name": "Mahima",
        "message": "ada thibbatu ne neh bn.",
        "time": "2m ago",
        "unread": 2,
        "online": true,
      },
      {
        "name": "Sachinthaka",
        "message": "Mn ada sadaruwaniwa dekka bn union room ek lagadi.",
        "time": "1h ago",
        "unread": 0,
        "online": false,
      },
      {
        "name": "Ravindu",
        "message": "Doni ekka bn enkot 12 pahu wei",
        "time": "3h ago",
        "unread": 1,
        "online": false,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Chats",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "4 conversations",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.cyan,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  // Navigate to New Chat (Generate QR)
                },
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: chats.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.cyan,
                      child: Icon(Icons.person, color: Colors.white, size: 26),
                    ),
                    if (chat['online'])
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['message'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      chat['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    if (chat['unread'] > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.cyan,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          chat['unread'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.cyan,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, size: 30, color: Colors.white),
          onPressed: () {
            // Could open QR Generator or new chat
          },
        ),
      ),
    );
  }
}
