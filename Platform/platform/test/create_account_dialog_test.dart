import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:landing_page/models/account_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/models/user_account.dart';
import 'package:landing_page/widgets/create_account_dialog.dart';

void main() {
  for (final size in [const Size(1440, 900), const Size(320, 640)]) {
    testWidgets(
      'create account validates and submits with the authenticated service at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var createdEmail = '';
        var createdPassword = '';
        var capturedIdempotencyKey = '';
        final attempts = <List<String>>[];
        UserAccount? dialogResult;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    dialogResult = await showDialog<UserAccount>(
                      context: context,
                      builder: (_) => CreateAccountDialog(
                        existingEmails: const ['existing@example.com'],
                        onCreateAccount:
                            ({
                              required email,
                              required password,
                              required idempotencyKey,
                            }) async {
                              createdEmail = email;
                              createdPassword = password;
                              capturedIdempotencyKey = idempotencyKey;
                              attempts.add([email, password, idempotencyKey]);
                              if (attempts.length == 1) {
                                throw Exception('Simulated connection loss');
                              }
                              return UserAccount(
                                id: 'created-id',
                                email: email,
                                roles: const [],
                                status: 'ACTIVE',
                                scope: 'GLOBAL',
                                createdAt: DateTime.utc(2026, 10, 14),
                              );
                            },
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        Future<void> submit() async {
          await tester.ensureVisible(
            find.byKey(const Key('create_account_submit')),
          );
          await tester.tap(find.byKey(const Key('create_account_submit')));
          await tester.pumpAndSettle();
        }

        await submit();
        expect(find.text('Ingresa el correo electrónico.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('create_account_email')),
          'correo-invalido',
        );
        await submit();
        expect(
          find.text('Ingresa un correo electrónico válido.'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('create_account_email')),
          'EXISTING@example.com',
        );
        await submit();
        expect(
          find.text('Ya existe una cuenta con este correo.'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('create_account_email')),
          'new@example.com',
        );
        await submit();
        expect(find.byKey(const Key('create_account_error')), findsOneWidget);
        expect(find.byKey(const Key('account_created_password')), findsNothing);
        await submit();
        await tester.pumpAndSettle();
        expect(attempts.length, 2);
        expect(attempts.last, attempts.first);
        expect(dialogResult, isNull);
        expect(AccountFormValidators.password(createdPassword), isNull);
        final credential = tester.widget<SelectableText>(
          find.byKey(const Key('account_created_password')),
        );
        expect(credential.data, createdPassword);
        String? clipboard;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.ensureVisible(
          find.byKey(const Key('account_created_copy')),
        );
        await tester.tap(find.byKey(const Key('account_created_copy')));
        await tester.pumpAndSettle();
        expect(clipboard, createdPassword);
        await tester.ensureVisible(
          find.byKey(const Key('account_created_confirm')),
        );
        await tester.tap(find.byKey(const Key('account_created_confirm')));
        await tester.pumpAndSettle();
        expect(dialogResult?.email, 'new@example.com');
        expect(find.byKey(const Key('account_created_password')), findsNothing);
        expect(createdEmail, 'new@example.com');
        expect(createdPassword.length, 24);
        expect(capturedIdempotencyKey, matches(RegExp(r'^[A-Fa-f0-9]{64}$')));
        expect(find.byKey(const Key('create_account_dialog')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
