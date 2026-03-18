import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class LyricPilotApp extends ConsumerWidget {
  const LyricPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(title: 'LyricPilot', debugShowCheckedModeBanner: false, theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme, themeMode: themeMode, routerConfig: router);
  }
}
