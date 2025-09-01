import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(providers: providers, child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Chatrio",
      routerConfig: router,
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 25, 200, 200),
          primary: const Color.fromARGB(255, 25, 200, 200),
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
