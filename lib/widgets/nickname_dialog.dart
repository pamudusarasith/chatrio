import 'package:flutter/material.dart';

class NicknameDialog extends StatefulWidget {
  const NicknameDialog({super.key});

  @override
  State<NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<NicknameDialog> {
  final TextEditingController _controller = TextEditingController();
  String nickname = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        'Chat Nickname',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Give this chat a nickname to remember it by:',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'e.g., John, Work Chat, Study Group',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              counterText: '', // Hide character counter
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
            ),
            onChanged: (value) {
              setState(() {
                nickname = value.trim();
              });
            },
            onSubmitted: (value) {
              nickname = value.trim();
              if (nickname.isNotEmpty) {
                Navigator.of(context).pop(nickname);
              }
            },
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: () {
            final finalNickname = _controller.text.trim();
            Navigator.of(
              context,
            ).pop(finalNickname.isEmpty ? 'Anonymous Chat' : finalNickname);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
