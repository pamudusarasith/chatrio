import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'views/home_page.dart';
import 'views/generate_qr_page.dart';
import 'views/scan_qr_page.dart';
import 'views/chat_list_page.dart';
import 'views/chat_page.dart';
import 'viewmodels/home_view_model.dart';
import 'viewmodels/generate_qr_view_model.dart';
import 'viewmodels/scan_qr_view_model.dart';
import 'viewmodels/chat_list_view_model.dart';
import 'viewmodels/chat_view_model.dart';

GoRouter get router {
  return GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final homeViewModel = HomeViewModel();
          return HomePage(viewModel: homeViewModel);
        },
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) {
          final chatsViewModel = ChatListViewModel();
          return ChatListPage(viewModel: chatsViewModel);
        },
      ),
      GoRoute(
        path: '/chat/:sessionId/:userName',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final userName = state.pathParameters['userName']!;
          final chatViewModel = ChatViewModel(
            sessionId: sessionId,
            otherUserName: userName,
          );
          return ChatPage(viewModel: chatViewModel);
        },
      ),
      GoRoute(
        path: '/generate-qr',
        builder: (context, state) {
          final generateQRViewModel = GenerateQRViewModel();
          return GenerateQRPage(viewModel: generateQRViewModel);
        },
      ),
      GoRoute(
        path: '/scan-qr',
        builder: (context, state) {
          final scanQRViewModel = ScanQRViewModel();
          return ScanQrPage(viewModel: scanQRViewModel);
        },
      ),
    ],
  );
}

extension GoRouteExtension on BuildContext {
  void navigate<T>(String route) =>
      kIsWeb ? GoRouter.of(this).go(route) : GoRouter.of(this).push(route);
}
