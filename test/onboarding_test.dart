import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:loki_llm/core/providers/shared_preferences_provider.dart';
import 'package:loki_llm/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildApp(SharedPreferences prefs) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      // Stub destination so context.go('/models') doesn't throw.
      GoRoute(
        path: '/models',
        builder: (_, __) => const Scaffold(body: Text('Models')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    // Match the app theme's classic ripple so page-transition ripples don't
    // load shaders/ink_sparkle.frag (which fails in the 3.41.0 test env).
    child: MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('OnboardingScreen — page content', () {
    testWidgets('first page shows Welcome to Loki LLM title', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      expect(find.text('Welcome to Loki LLM'), findsOneWidget);
    });

    testWidgets('first page shows privacy-focused body text', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      expect(
        find.text(
          'Run powerful AI models entirely on your device — private, offline, and fast.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('second page shows Download a Model title', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Download a Model'), findsOneWidget);
    });

    testWidgets('third page shows Chat and Use Documents title', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Chat & Use Documents'), findsOneWidget);
    });
  });

  group('OnboardingScreen — navigation buttons', () {
    testWidgets('first page shows Next button, not Get Started', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('first page does not show Back button', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      expect(find.text('Back'), findsNothing);
    });

    testWidgets('second page shows both Back and Next', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('third page shows Get Started and Back, no Next', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('tapping Back on second page returns to first', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Download a Model'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Loki LLM'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });
  });

  group('OnboardingScreen — finish flow', () {
    testWidgets('tapping Get Started persists onboarding_complete=true',
        (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      // Navigate to last page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(prefs.getBool('onboarding_complete'), isTrue);
    });

    testWidgets('tapping Get Started navigates to /models', (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // The stub route renders 'Models' text
      expect(find.text('Models'), findsOneWidget);
    });
  });
}
