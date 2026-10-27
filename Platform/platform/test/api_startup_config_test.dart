import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:landing_page/config/api_config.dart';
import 'package:landing_page/main.dart';
import 'package:landing_page/providers/auth_providers.dart';
import 'package:landing_page/views/home_page.dart';

import 'support/auth_fixtures.dart';

void main() {
  testWidgets(
    'login button sends HTTP using startup defaults without defines',
    (tester) async {
      final config = await ApiConfig.loadForStartup();
      final requests = <String>[];
      final client = MockClient((request) async {
        requests.add('${request.method} ${request.url}');
        return defaultHandler(request);
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authHttpClientProvider.overrideWithValue(client)],
          child: MyApp(
            apiConfig: config,
            initialRoute: '/login',
            theme: ThemeData(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('login_email')),
        'fixture@example.invalid',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'test-marker',
      );
      await tester.ensureVisible(find.byKey(const Key('login_submit')));
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(requests, isNotEmpty);
      expect(requests.first, 'POST http://3.148.192.204/api/v1/auth/login');
      expect(requests, contains('GET http://3.148.192.204/api/v1/auth/me'));
      expect(
        requests.every(
          (request) => request
              .split(' ')
              .last
              .startsWith('http://3.148.192.204/api/v1/'),
        ),
        isTrue,
      );
      expect(
        find.textContaining('El servicio de acceso no está configurado'),
        findsNothing,
      );
      expect(find.byType(HomePage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'startup and the shared provider use the same API for every service',
    () async {
      final config = await ApiConfig.loadForStartup();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sharedConfig = container.read(apiConfigProvider)!;
      for (final path in [
        '/api/v1/auth/login',
        '/api/v1/auth/me',
        '/api/v1/auth/refresh',
        '/api/v1/auth/logout',
        '/api/v1/organizations',
      ]) {
        expect(config.endpoint(path).toString(), 'http://3.148.192.204$path');
        expect(sharedConfig.endpoint(path), config.endpoint(path));
      }
    },
  );

  test('build flags cannot replace the global API with localhost', () {
    expect(
      ApiConfig.fromEnvironment().endpoint('/api/v1/auth/login').toString(),
      'http://3.148.192.204/api/v1/auth/login',
    );
  });

  test(
    'the configured HTTP API is allowed without enabling arbitrary HTTP',
    () {
      expect(
        ApiConfig(
          ApiConfig.apiBaseUrl,
        ).endpoint('/api/v1/auth/login').toString(),
        'http://3.148.192.204/api/v1/auth/login',
      );
      for (final url in [
        'http://api.example.com',
        'http://127.0.0.1:8091',
        'http://3.148.192.204:8091',
        'http://3.148.192.204.evil.example',
      ]) {
        expect(() => ApiConfig(url), throwsFormatException);
      }
    },
  );
}
