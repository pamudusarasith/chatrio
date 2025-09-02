import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/chat_list_view_model.dart';
import '../models/chat.dart';
import '../widgets/loading_view_widget.dart';
import '../models/extension_request.dart';
import '../widgets/error_view_widget.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key, required this.viewModel});

  final ChatListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.refreshChats(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, child) {
            return _buildBody(context, viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatListViewModel chatListViewModel) {
    if (chatListViewModel.errorMessage != null) {
      return _buildErrorView(context, chatListViewModel);
    }
    if (chatListViewModel.isLoading) {
      return _buildLoadingView(context);
    }
    return _buildChatList(context, chatListViewModel);
  }

  Widget _buildLoadingView(BuildContext context) {
    return const LoadingViewWidget(message: "Loading chats...");
  }

  Widget _buildErrorView(
    BuildContext context,
    ChatListViewModel chatListViewModel,
  ) {
    return ErrorViewWidget(
      errorMessage: chatListViewModel.errorMessage ?? "An error occurred",
      onRetry: () {
        chatListViewModel.clearError();
        chatListViewModel.refreshChats();
      },
    );
  }

  Widget _buildChatList(
    BuildContext context,
    ChatListViewModel chatListViewModel,
  ) {
    if (!chatListViewModel.hasChats &&
        chatListViewModel.incomingRequests.isEmpty &&
        chatListViewModel.myPendingRequests.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => chatListViewModel.refreshChats(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          if (chatListViewModel.myPendingRequests.isNotEmpty) ...[
            _buildSectionHeader('Waiting for Approval', Icons.hourglass_top),
            const SizedBox(height: 12),
            ...chatListViewModel.myPendingRequests.map(
              (req) => _buildWaitingTile(context, chatListViewModel, req),
            ),
            const SizedBox(height: 20),
          ],
          if (chatListViewModel.incomingRequests.isNotEmpty) ...[
            _buildSectionHeader('Requests', Icons.timer_outlined),
            const SizedBox(height: 12),
            ...chatListViewModel.incomingRequests.map(
              (req) => _buildExtensionTile(context, chatListViewModel, req),
            ),
            const SizedBox(height: 20),
          ],
          if (chatListViewModel.activeChats.isNotEmpty) ...[
            _buildSectionHeader('Active Chats', Icons.chat_bubble),
            const SizedBox(height: 12),
            ...chatListViewModel.activeChats.map(
              (chat) => _buildChatTile(context, chat, chatListViewModel, false),
            ),
          ],

          if (chatListViewModel.expiredChats.isNotEmpty) ...[
            if (chatListViewModel.activeChats.isNotEmpty)
              const SizedBox(height: 32),
            _buildSectionHeader('Expired Chats', Icons.schedule),
            const SizedBox(height: 12),
            ...chatListViewModel.expiredChats.map(
              (chat) => _buildChatTile(context, chat, chatListViewModel, true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaitingTile(
    BuildContext context,
    ChatListViewModel vm,
    ExtensionRequest req,
  ) {
    final chat = (vm.activeChats + vm.expiredChats).firstWhere(
      (c) => c.chatId == req.chatId,
      orElse: () => Chat(
        chatId: req.chatId,
        creator: '',
        joiner: '',
        createdAt: 0,
        expiresAt: 0,
        isActive: false,
      ),
    );
    final name = vm.getChatDisplayName(chat);
    final minutes = req.additionalMinutes;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Waiting for "$name" to approve +$minutes min',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionTile(
    BuildContext context,
    ChatListViewModel vm,
    ExtensionRequest req,
  ) {
    final chat = (vm.activeChats + vm.expiredChats).firstWhere(
      (c) => c.chatId == req.chatId,
      orElse: () => Chat(
        chatId: req.chatId,
        creator: '',
        joiner: '',
        createdAt: 0,
        expiresAt: 0,
        isActive: false,
      ),
    );
    final name = vm.getChatDisplayName(chat);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Extend "$name" by ${req.additionalMinutes} minutes?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await vm.rejectExtension(req.chatId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok ? 'Request rejected' : 'Failed to reject',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final ok = await vm.approveExtension(req.chatId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok ? 'Extension approved' : 'Failed to approve',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new chat by generating or scanning a QR code',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    Chat chat,
    ChatListViewModel chatListViewModel,
    bool isExpired,
  ) {
    final displayName = chatListViewModel.getChatDisplayName(chat);
    final lastMessage = chatListViewModel.getLastMessage(chat.chatId);
    final lastMessageText = lastMessage?.text ?? 'No messages yet';
    final lastMessageTime = lastMessage != null
        ? chatListViewModel.getFormattedDate(lastMessage.timestamp)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.grey[300]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (isExpired) {
              // If there's a pending request for this chat, we prefer inline actions; still allow sheet
              // No-op; we keep bottom sheet for expired chats regardless of pending state
              // Ask user to delete or request an extension
              final action = await showModalBottomSheet<String>(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.timer_outlined),
                          title: const Text('Request time extension'),
                          onTap: () => Navigator.of(ctx).pop('extend'),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'Delete chat',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () => Navigator.of(ctx).pop('delete'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );

              if (action == 'delete') {
                // Confirm delete
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
                  await chatListViewModel.deleteChat(chat.chatId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat deleted')),
                    );
                  }
                }
              } else if (action == 'extend') {
                // Ask how many minutes to extend
                final minutes = await _pickExtensionMinutes(context);
                if (minutes != null) {
                  // Use a light-weight ChatService flow via a temporary view model
                  final userId = chatListViewModel.currentUserId;
                  if (userId != null) {
                    // Defer to ChatService through a simple helper dialog action
                    final success = await _requestExtension(
                      context,
                      chat.chatId,
                      minutes,
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Extension request sent for $minutes minutes',
                          ),
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to send extension request'),
                        ),
                      );
                    }
                  }
                }
              }
              return;
            }
            context.push('/chat/${chat.chatId}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.grey[400]
                        : Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isExpired
                              ? Colors.grey[600]
                              : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: lastMessage == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                      // No inline extension actions
                    ],
                  ),
                ),
                if (lastMessageTime.isNotEmpty)
                  Text(
                    lastMessageTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
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

Future<int?> _showNumberPickerDialog(BuildContext context) async {
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

Future<int?> _pickExtensionMinutes(BuildContext context) async {
  return _showNumberPickerDialog(context);
}

Future<bool> _requestExtension(
  BuildContext context,
  String chatId,
  int minutes,
) async {
  try {
    // Acquire ChatService via UserService id already initialized on app
    // We'll get an instance, or create if not available.
    final userService = UserService();
    final user = await userService.getCurrentUser();
    var chatService = ChatService.instance;
    if (chatService == null || chatService.userId != user.id) {
      chatService = ChatService(userId: user.id);
      await chatService.initialize();
    }
    final ok = await chatService.requestChatExtension(chatId, minutes);
    await chatService.syncChatFromFirebase(chatId);
    return ok;
  } catch (_) {
    return false;
  }
}
