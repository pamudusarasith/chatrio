import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'views/home_page.dart';
import 'views/splash_page.dart';
import 'views/generate_qr_page.dart';
import 'views/scan_qr_page.dart';
import 'views/chat_list_page.dart';
import 'views/chat_page.dart';
import 'viewmodels/home_view_model.dart';
import 'viewmodels/generate_qr_view_model.dart';
import 'viewmodels/scan_qr_view_model.dart';
import 'viewmodels/chat_list_view_model.dart';
import 'viewmodels/chat_page_view_model.dart';

GoRouter get router {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final homeViewModel = HomeViewModel();
          return HomePage(viewModel: homeViewModel);
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
      GoRoute(
        path: '/chats',
        builder: (context, state) {
          final chatListViewModel = ChatListViewModel();
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              context.go('/');
            },
            child: ChatListPage(viewModel: chatListViewModel),
          );
        },
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          final viewModel = ChatPageViewModel(chatId: chatId);
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) => {
              if (context.canPop())
                {context.pop()}
              else
                {context.navigate('/chats')},
            },
            child: ChatPage(viewModel: viewModel),
          );
        },
      ),
    ],
  );
}

extension GoRouteExtension on BuildContext {
  void navigate<T>(String route) =>
      kIsWeb ? GoRouter.of(this).go(route) : GoRouter.of(this).push(route);
}
