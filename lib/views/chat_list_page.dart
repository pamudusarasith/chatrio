import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/chat_list_view_model.dart';
import '../models/chat.dart';
import '../widgets/loading_view_widget.dart';
import '../models/extension_request.dart';
import '../widgets/error_view_widget.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../utils/logger.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key, required this.viewModel});

  final ChatListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
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
    final cs = Theme.of(context).colorScheme;
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
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.hourglass_top, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Waiting for "$name" to approve +$minutes min',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;
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
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Extend "$name" by ${req.additionalMinutes} minutes?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new chat by generating or scanning a QR code',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    // Use subtle onSurfaceVariant for section headers
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    Chat chat,
    ChatListViewModel chatListViewModel,
    bool isExpired,
  ) {
    final cs = Theme.of(context).colorScheme;
    final displayName = chatListViewModel.getChatDisplayName(chat);
    final lastMessage = chatListViewModel.getLastMessage(chat.chatId);
    final lastMessageText = lastMessage?.text ?? 'No messages yet';
    final lastMessageTime = lastMessage != null
        ? chatListViewModel.getFormattedDate(lastMessage.timestamp)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1),
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
                  final cs = Theme.of(ctx).colorScheme;
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: Icon(
                            Icons.timer_outlined,
                            color: cs.primary,
                          ),
                          title: const Text('Request time extension'),
                          onTap: () => Navigator.of(ctx).pop('extend'),
                        ),
                        ListTile(
                          leading: Icon(Icons.delete_outline, color: cs.error),
                          title: Text(
                            'Delete chat',
                            style: TextStyle(color: cs.error),
                          ),
                          onTap: () => Navigator.of(ctx).pop('delete'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
              if (!context.mounted) return;

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
                        child: Text(
                          'Delete',
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
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
                if (!context.mounted) return;
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
            context.go('/chat/${chat.chatId}');
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
                        ? cs.surfaceContainerHighest
                        : cs.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: isExpired
                        ? cs.onSurfaceVariant
                        : cs.onPrimaryContainer,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isExpired
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
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
    final userService = UserService();
    final user = await userService.getCurrentUser();
    var chatService = ChatService.instance;
    if (chatService == null || chatService.userId != user.id) {
      chatService = ChatService(userId: user.id);
      await chatService.initialize();
    }
    AppLogger.info(
      'Requesting chat extension: chatId=$chatId, userId=${user.id}, minutes=$minutes',
    );
    final ok = await chatService.requestChatExtension(chatId, minutes);
    AppLogger.info(
      'Chat extension request result: chatId=$chatId, success=$ok',
    );
    await chatService.syncChatFromFirebase(chatId);
    return ok;
  } catch (e, stack) {
    AppLogger.error(
      'Error requesting chat extension: chatId=$chatId, error=${e.toString()}',
      e,
      stack,
    );
    return false;
  }
}
