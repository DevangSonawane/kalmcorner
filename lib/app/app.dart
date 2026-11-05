import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:calmcorner/l10n/app_localizations.dart';

import 'package:calmcorner/core/providers.dart';

import 'brand.dart';
import 'router.dart';
import 'theme/themes.dart';
import 'theme/tokens.dart' show AppThemeMode;

class CalmCornerApp extends ConsumerWidget {
  const CalmCornerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: buildDawnTheme(),
      darkTheme: themeMode == AppThemeMode.moonlit
          ? buildMoonlitTheme()
          : buildDuskTheme(),
      themeMode: switch (themeMode) {
        AppThemeMode.auto => ThemeMode.system,
        AppThemeMode.dawn => ThemeMode.light,
        AppThemeMode.dusk || AppThemeMode.moonlit => ThemeMode.dark,
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi')],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.6),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    final saved = ref.read(prefsStoreProvider).getString('settings.theme');
    return AppThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => AppThemeMode.auto,
    );
  }

  void setThemeMode(AppThemeMode mode) {
    state = mode;
    ref.read(prefsStoreProvider).setString('settings.theme', mode.name);
  }
}
