import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/logger.dart';
import '../firebase_options.dart';
import '../database/database_manager.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../widgets/splash_view_widget.dart';
import '../widgets/error_view_widget.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _error = null);
    try {
      // Ensure Firebase is initialized before any Firebase usage
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('Firebase initialized');

      // Prepare local database and cleanup
      final db = DatabaseManager();
      await db.database; // open DB
      await db.cleanupExpiredData();
      AppLogger.info('Local database ready');

      // Ensure user exists
      final userService = UserService();
      final user = await userService.getCurrentUser();
      AppLogger.info('User initialized: ${user.id}');

      // Initialize chat service listeners and pending fetch early
      final chatService = ChatService(userId: user.id);
      try {
        await chatService.initialize().timeout(const Duration(seconds: 8));
        AppLogger.info('Chat service initialized');
      } on TimeoutException {
        AppLogger.warning('Chat service initialization timed out');
        throw Exception('Chat service took too long to initialize');
      }

      if (!mounted) return;
      // Navigate to home
      context.go('/');
    } catch (e) {
      setState(() => _error = 'Initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: ErrorViewWidget(
            errorMessage: _error!,
            onRetry: _initialize,
            retryButtonText: 'Retry',
          ),
        ),
      );
    }

    return const Scaffold(body: SafeArea(child: SplashViewWidget()));
  }
}
