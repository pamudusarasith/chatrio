import 'package:flutter/material.dart';
import '../router.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/splash_view_widget.dart';
import '../widgets/error_view_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  Widget _buildBody(BuildContext context, HomeViewModel homeViewModel) {
    // Show error state
    if (homeViewModel.errorMessage != null) {
      return _buildErrorView(context, homeViewModel);
    }

    // Show loading state
    if (homeViewModel.isLoading) {
      return _buildLoadingView(context);
    }

    // Show main content
    return _buildMainContent(context, homeViewModel);
  }

  Widget _buildLoadingView(BuildContext context) {
    return const SplashViewWidget();
  }

  Widget _buildErrorView(BuildContext context, HomeViewModel homeViewModel) {
    return ErrorViewWidget(
      errorMessage: homeViewModel.errorMessage ?? "An error occurred",
      onRetry: () {
        homeViewModel.clearError();
        homeViewModel.initializeUser();
      },
      retryButtonText: "Retry",
    );
  }

  Widget _buildMainContent(BuildContext context, HomeViewModel homeViewModel) {
    ThemeData theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "assets/logo.png", // Fixed asset path
            height: 70,
          ),
          const SizedBox(height: 15),
          Text(
            'Chatrio',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Connect instantly with friends",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  spreadRadius: 3,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset(
                "assets/home_screen_image.jpg",
                height: 140,
                width: 270,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // My Chats Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(270, 0),
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              textStyle: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("My Chats"),
            onPressed: homeViewModel.isUserInitialized
                ? () {
                    context.navigate("/chats");
                  }
                : null,
          ),

          const SizedBox(height: 20),

          // Start New Chat (QR) Button as clickable text
          MouseRegion(
            cursor: homeViewModel.isUserInitialized
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: homeViewModel.isUserInitialized
                  ? () {
                      context.navigate("/generate-qr");
                    }
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    color: homeViewModel.isUserInitialized
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Start New Chat (Generate QR)",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: homeViewModel.isUserInitialized
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Scan QR to Join Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(270, 0),
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
            ),
            icon: Icon(
              Icons.filter_center_focus,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              "Scan QR to Join",
              style: TextStyle(fontSize: 15, color: theme.colorScheme.primary),
            ),
            onPressed: homeViewModel.isUserInitialized
                ? () {
                    context.navigate("/scan-qr");
                  }
                : null,
          ),

          const SizedBox(height: 20),

          // Share QR tip text
          Text(
            "Share QR codes to connect instantly • No signup required",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
