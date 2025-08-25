import 'package:flutter/material.dart';

ThemeData getAppTheme(BuildContext context) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Color.fromARGB(255, 25, 200, 200),
    // brightness: MediaQuery.platformBrightnessOf(context),
  );

  return ThemeData(
    scaffoldBackgroundColor: colorScheme.surface,
    colorScheme: colorScheme,
  );
}
