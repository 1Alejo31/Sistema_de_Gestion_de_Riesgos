import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/controllers/auth_controller.dart';
import 'package:landing_page/providers/auth_providers.dart';

import 'support/auth_fixtures.dart';

void main() {
  test('Riverpod publishes immutable login and logout snapshots', () async {
    final pending = Completer<http.Response>();
    final auth = createAuth(
      handler: (request) => request.url.path.endsWith('/login')
          ? pending.future
          : defaultHandler(request),
    );
    addTearDown(auth.dispose);
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    final snapshots = <AuthState>[];
    container.listen(authStateProvider, (_, next) => snapshots.add(next));
    final signedOut = container.read(authStateProvider);
    final login = container
        .read(authControllerProvider)
        .login('persona@example.com', 'password');
    expect(container.read(authStateProvider).isBusy, isTrue);
    expect(signedOut.status, AuthStatus.signedOut);
    pending.complete(sessionResponse());
    expect(await login, isTrue);
    final authenticated = container.read(authStateProvider);
    expect(authenticated.identity?.email, 'persona@example.com');
    expect(authenticated.isAuthenticated, isTrue);
    await auth.logout();
    expect(container.read(authStateProvider).isAuthenticated, isFalse);
    expect(container.read(authStateProvider).identity, isNull);
    expect(authenticated.isAuthenticated, isTrue);
    expect(snapshots.map((value) => value.status), [
      AuthStatus.signingIn,
      AuthStatus.authenticated,
      AuthStatus.signingOut,
      AuthStatus.signedOut,
    ]);
  });

  test(
    'a new application scope does not inherit another scope session',
    () async {
      final firstAuth = createAuth();
      final secondAuth = createAuth();
      addTearDown(firstAuth.dispose);
      addTearDown(secondAuth.dispose);
      final first = ProviderContainer(
        overrides: [authControllerProvider.overrideWithValue(firstAuth)],
      );
      final second = ProviderContainer(
        overrides: [authControllerProvider.overrideWithValue(secondAuth)],
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      first.read(authStateProvider);
      second.read(authStateProvider);
      await firstAuth.login('persona@example.com', 'password');
      expect(first.read(authStateProvider).isAuthenticated, isTrue);
      expect(second.read(authStateProvider).isAuthenticated, isFalse);
    },
  );

  test('provider disposal detaches the injected controller listener', () async {
    final auth = createAuth();
    addTearDown(auth.dispose);
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWithValue(auth)],
    );
    container.read(authStateProvider);
    container.dispose();
    // Notifications must not reach a disposed Notifier. An injected controller
    // remains owned by the caller and must still be usable.
    expect(await auth.login('persona@example.com', 'password'), isTrue);
  });
}
