import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'views/home_page.dart';
import 'views/generate_qr_page.dart';
import 'views/scan_qr_page.dart';
import 'views/create_account_page.dart';
import 'views/sign_in_page.dart';
import 'viewmodels/create_account_view_model.dart';
import 'viewmodels/sign_in_view_model.dart';
import 'viewmodels/generate_qr_view_model.dart';

GoRouter get router {
  return GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/generate-qr',
        builder: (context, state) {
          final generateQRViewModel = GenerateQRViewModel(context.read());
          return GenerateQRPage(viewModel: generateQRViewModel);
        },
      ),
      GoRoute(
        path: '/scan-qr',
        builder: (context, state) => const ScanQrPage(),
      ),
      GoRoute(
        path: '/create-account',
        builder: (context, state) {
          final createAccountViewModel = CreateAccountViewModel();
          return CreateAccountPage(viewModel: createAccountViewModel);
        },
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) {
          final signInViewModel = SignInViewModel();
          return SignInPage(viewModel: signInViewModel);
        },
      ),
    ],
  );
}

extension GoRouteExtension on BuildContext {
  void navigate<T>(String route) =>
      kIsWeb ? GoRouter.of(this).go(route) : GoRouter.of(this).push(route);
}
