import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/objectbox_store.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/model_io_logger.dart';
import 'core/providers/objectbox_provider.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  // Run inside a guarded zone so uncaught async errors reach AppLogger.
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppLogger.instance.init();
    await ModelIoLogger.instance.init();

    // Route Flutter framework errors into our logger as well.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLogger.instance.error(
        'FlutterError',
        details.exceptionAsString(),
        details.exception,
        details.stack,
      );
      previousOnError?.call(details);
    };

    // Catch errors raised by the platform/engine (incl. plugin callbacks).
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.instance
          .error('PlatformDispatcher', 'Uncaught error', error, stack);
      return false;
    };

    final store = await openObjectBoxStore();
    final prefs = await SharedPreferences.getInstance();
    AppLogger.instance.info('main', 'ObjectBox + SharedPreferences ready');

    runApp(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWithValue(store),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // Last-resort handler for anything that escapes the zone.
    AppLogger.instance.error('Zone', 'Uncaught zone error', error, stack);
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'Loki LLM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
