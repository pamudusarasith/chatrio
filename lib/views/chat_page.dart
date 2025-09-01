import 'package:flutter/material.dart';
import '../viewmodels/chat_page_view_model.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';

class ChatPage extends StatelessWidget {
  final ChatPageViewModel viewModel;

  const ChatPage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        title: Text(
          viewModel.getChatDisplayName(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete chat',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete chat?'),
                  content: const Text(
                    'This will remove the chat and its messages from your device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final ok = await viewModel.deleteChat();
                if (!context.mounted) return;
                if (ok) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete chat')),
                  );
                }
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Expired banner
            ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                final chat = viewModel.chat;
                final expired =
                    chat?.isExpired() == true || !(chat?.isActive ?? false);
                if (!expired) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  color: Colors.amber[100],
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This chat has expired. You can delete it or request an extension.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final minutes = await _pickExtensionMinutes(context);
                          if (minutes != null) {
                            final success = await _requestExtension(
                              context,
                              viewModel.chatId,
                              minutes,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Extension request sent'
                                        : 'Failed to send request',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Extend'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete chat?'),
                              content: const Text(
                                'This will remove the chat and its messages from your device.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            final ok = await viewModel.deleteChat();
                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chat deleted')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to delete chat'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, child) {
                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (viewModel.errorMessage != null) {
                    return Center(child: Text(viewModel.errorMessage!));
                  }
                  final expired =
                      (viewModel.chat?.isExpired() == true) ||
                      !(viewModel.chat?.isActive ?? true);
                  if (expired) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: Icon(
                              Icons.lock_clock,
                              size: 48,
                              color: Colors.amber[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chat expired',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Request an extension or delete the chat.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  final minutes = await _pickExtensionMinutes(
                                    context,
                                  );
                                  if (minutes != null) {
                                    final success = await _requestExtension(
                                      context,
                                      viewModel.chatId,
                                      minutes,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Extension request sent'
                                                : 'Failed to send request',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Request extension'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.tonal(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete chat?'),
                                      content: const Text(
                                        'This will remove the chat and its messages from your device.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    final ok = await viewModel.deleteChat();
                                    if (!context.mounted) return;
                                    if (ok) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Chat deleted'),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to delete chat',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  final messages = viewModel.messages;
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMe = message.sender == viewModel.currentUserId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Theme.of(context).primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isMe
                                      ? null
                                      : Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.text,
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.grey[800],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      viewModel.getFormattedDate(
                                        message.timestamp,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMe
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, ChatPageViewModel viewModel) {
    final controller = viewModel.messageController;
    final expired =
        (viewModel.chat?.isExpired() == true) ||
        !(viewModel.chat?.isActive ?? true);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListenableBuilder(
                    listenable: viewModel,
                    builder: (context, child) {
                      return TextField(
                        controller: controller,
                        enabled: !viewModel.isSending && !expired,
                        decoration: InputDecoration(
                          hintText: expired
                              ? 'Chat expired'
                              : 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: viewModel.isSending
                            ? null
                            : expired
                            ? null
                            : (_) => viewModel.sendMessage(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: expired
                      ? Colors.grey[300]
                      : Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, child) {
                    return IconButton(
                      icon: viewModel.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                      onPressed: viewModel.isSending || expired
                          ? null
                          : viewModel.sendMessage,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<int?> _pickExtensionMinutes(BuildContext context) async {
  final controller = TextEditingController(text: '10');
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Extend by (minutes)'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: 'e.g., 10'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final v = int.tryParse(controller.text.trim());
            if (v == null || v <= 0) {
              Navigator.of(ctx).pop();
            } else {
              Navigator.of(ctx).pop(v);
            }
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
  return result;
}

Future<bool> _requestExtension(
  BuildContext context,
  String chatId,
  int minutes,
) async {
  try {
    final userService = UserService();
    final user = await userService.getCurrentUser();
    var chatService = ChatService.instance;
    if (chatService == null || chatService.userId != user.id) {
      chatService = ChatService(userId: user.id);
      await chatService.initialize();
    }
    final ok = await chatService.requestChatExtension(chatId, minutes);
    // Try to refresh local chat after request (approval may come later via listener)
    await chatService.syncChatFromFirebase(chatId);
    return ok;
  } catch (_) {
    return false;
  }
}
