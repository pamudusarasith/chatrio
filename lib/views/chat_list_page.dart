import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/chat_list_view_model.dart';
import '../models/chat.dart';
import '../widgets/loading_view_widget.dart';
import '../widgets/error_view_widget.dart';

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
    // Show error state
    if (chatListViewModel.errorMessage != null) {
      return _buildErrorView(context, chatListViewModel);
    }

    // Show loading state
    if (chatListViewModel.isLoading) {
      return _buildLoadingView(context);
    }

    // Show main content
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
    if (!chatListViewModel.hasChats) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => chatListViewModel.refreshChats(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // Active chats section
          if (chatListViewModel.activeChats.isNotEmpty) ...[
            _buildSectionHeader('Active Chats', Icons.chat_bubble),
            const SizedBox(height: 12),
            ...chatListViewModel.activeChats.map(
              (chat) => _buildChatTile(context, chat, chatListViewModel, false),
            ),
          ],

          // Expired chats section
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
          onTap: () {
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
