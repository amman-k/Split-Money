import 'package:flutter/material.dart';
import 'package:split_frontend/core/router/app_router.dart';
import 'package:split_frontend/core/theme/app_theme.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';

class SplitApp extends StatelessWidget {
  const SplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SplitEase',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
    );
  }
}
