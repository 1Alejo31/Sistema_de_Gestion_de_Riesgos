import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../models/account_form_validators.dart';
import '../models/api_failure.dart';
import '../providers/auth_providers.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;
  bool _redirectScheduled = false;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider)
          .changePassword(_current.text, _password.text);
      if (!mounted) return;
      _current.clear();
      _password.clear();
      _confirmation.clear();
      // The application session listener navigates to login after revocation.
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.supportMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo confirmar el cambio. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated || !auth.passwordChangeRequired) {
      if (!_redirectScheduled) {
        _redirectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              auth.isAuthenticated ? '/home' : '/login',
              (_) => false,
            );
          }
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F6FC),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_reset,
                          size: 44,
                          color: AppTheme.dashboardBlue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Actualiza tu contraseña',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.dashboardBlueDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Antes de continuar, reemplaza tu contraseña inicial. Al terminar deberás iniciar sesión con la nueva contraseña.',
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          key: const Key('change_current_password'),
                          controller: _current,
                          enabled: !_busy,
                          obscureText: _hidden,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña actual',
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ingresa tu contraseña actual.'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          key: const Key('change_new_password'),
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _hidden,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Nueva contraseña',
                          ),
                          validator: (value) =>
                              AccountFormValidators.password(value) ??
                              (value == _current.text
                                  ? 'La nueva contraseña debe ser distinta de la actual.'
                                  : null),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Entre 14 y 128 caracteres, con mayúscula, minúscula, número y símbolo.',
                          style: TextStyle(color: AppTheme.dashboardMuted),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          key: const Key('change_confirm_password'),
                          controller: _confirmation,
                          enabled: !_busy,
                          obscureText: _hidden,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Confirma la nueva contraseña',
                          ),
                          validator: (value) =>
                              AccountFormValidators.confirmation(
                                value,
                                _password.text,
                              ),
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        TextButton.icon(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _hidden = !_hidden),
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          label: Text(
                            _hidden
                                ? 'Mostrar contraseñas'
                                : 'Ocultar contraseñas',
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              semanticsLabel: _error,
                            ),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          key: const Key('change_password_submit'),
                          onPressed: _busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dashboardBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(18),
                          ),
                          child: Text(
                            _busy ? 'Actualizando…' : 'Cambiar contraseña',
                          ),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => ref.read(authControllerProvider).logout(),
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
