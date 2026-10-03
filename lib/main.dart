// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../state/auth_provider.dart';
import '../state/factory_store.dart';
import '../widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      path: 'lib/l10n',
      fallbackLocale: const Locale('ar', 'SA'),
      startLocale: const Locale('ar', 'SA'),
      child: const PlasticFactoryApp(),
    ),
  );
}

class PlasticFactoryApp extends StatefulWidget {
  const PlasticFactoryApp({super.key});

  @override
  State<PlasticFactoryApp> createState() => _PlasticFactoryAppState();
}

class _PlasticFactoryAppState extends State<PlasticFactoryApp> {
  late final FactoryStore _factoryStore;

  @override
  void initState() {
    super.initState();
    _factoryStore = FactoryStore();
  }

  @override
  void dispose() {
    _factoryStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _factoryStore),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListenableBuilder(
            listenable: _factoryStore,
            builder: (context, _) {
              return MaterialApp(
                title: 'النجمة بلاست - نظام إدارة الإنتاج والمخزون',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.themeData,
                themeMode: themeProvider.themeMode,
                localizationsDelegates: EasyLocalization.of(context) != null
                    ? context.localizationDelegates
                    : null,
                supportedLocales: EasyLocalization.of(context) != null
                    ? context.supportedLocales
                    : const [Locale('ar', 'SA'), Locale('en', 'US')],
                locale: EasyLocalization.of(context) != null
                    ? context.locale
                    : const Locale('ar', 'SA'),
                home: const AuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}
