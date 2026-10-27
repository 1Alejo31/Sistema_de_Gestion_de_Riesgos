import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';
import '../models/api_failure.dart';
import '../models/account_form_validators.dart';
import '../models/user_account.dart';
import '../models/initial_password.dart';
import '../services/users_service.dart';

typedef CreateAccount =
    Future<UserAccount> Function({
      required String email,
      required String password,
      required String idempotencyKey,
    });

class CreateAccountDialog extends StatefulWidget {
  const CreateAccountDialog({
    super.key,
    required this.onCreateAccount,
    this.existingEmails = const [],
    this.onAccountCreated,
  });

  final CreateAccount onCreateAccount;
  final List<String> existingEmails;
  final VoidCallback? onAccountCreated;

  @override
  State<CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<CreateAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  UserAccount? _created;
  bool _copied = false;
  String? _copyError;
  bool _isSubmitting = false;
  String? _error;
  String? _pendingIdempotencyKey;
  String? _pendingEmail;
  String? _pendingPassword;

  @override
  void dispose() {
    _email.dispose();
    _pendingPassword = null;
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final invalid = AccountFormValidators.email(value);
    if (invalid != null) return invalid;
    final normalized = value!.trim().toLowerCase();
    if (widget.existingEmails.any(
      (email) => email.toLowerCase() == normalized,
    )) {
      return 'Ya existe una cuenta con este correo.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || _created != null) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    if (_pendingIdempotencyKey == null || _pendingEmail != email) {
      _pendingIdempotencyKey = UsersService.newIdempotencyKey();
      _pendingEmail = email;
      _pendingPassword = generateInitialPassword();
    }
    setState(() => _isSubmitting = true);
    try {
      final created = await widget.onCreateAccount(
        email: email,
        password: _pendingPassword!,
        idempotencyKey: _pendingIdempotencyKey!,
      );
      if (mounted) {
        setState(() => _created = created);
        widget.onAccountCreated?.call();
      }
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.supportMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo confirmar la creación. Puedes reintentar con los mismos datos.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _copyPassword() async {
    try {
      await Clipboard.setData(ClipboardData(text: _pendingPassword!));
      if (mounted) {
        setState(() {
          _copied = true;
          _copyError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _copyError =
              'No se pudo copiar. Selecciona la contraseña y cópiala manualmente.',
        );
      }
    }
  }

  void _finish() {
    Navigator.pop(context, _created);
  }

  Widget _successDialog() => AlertDialog(
    key: const Key('account_created_alert'),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    insetPadding: const EdgeInsets.all(16),
    scrollable: true,
    title: const Column(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          key: Key('account_created_icon'),
          color: AppTheme.dashboardGreen,
          size: 56,
        ),
        SizedBox(height: 14),
        Text(
          '¡Cuenta creada con éxito!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.dashboardBlueDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _created!.email,
            key: const Key('account_created_email'),
            style: const TextStyle(
              color: AppTheme.dashboardBlueDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.dashboardBlue.withValues(alpha: .06),
              border: Border.all(color: AppTheme.dashboardLine),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Contraseña inicial generada',
                  style: TextStyle(
                    color: AppTheme.dashboardBlueDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cópiala y entrégala a la persona por un medio privado. '
                  'Solo estará disponible mientras esta ventana permanezca abierta. '
                  'Al cerrarla, no podrás volver a consultarla.',
                  style: TextStyle(color: AppTheme.dashboardMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  _pendingPassword!,
                  key: const Key('account_created_password'),
                  style: const TextStyle(
                    color: AppTheme.dashboardBlueDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('account_created_copy'),
                  onPressed: _copyPassword,
                  icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
                  label: Text(
                    _copied ? 'Contraseña copiada' : 'Copiar contraseña',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.dashboardBlue,
                    side: const BorderSide(color: AppTheme.dashboardLine),
                  ),
                ),
                if (_copyError != null)
                  Text(
                    _copyError!,
                    style: const TextStyle(color: AppTheme.dashboardRed),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    actions: [
      FilledButton(
        key: const Key('account_created_confirm'),
        onPressed: _finish,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.dashboardBlue,
          foregroundColor: Colors.white,
        ),
        child: const Text('Ya la compartí · cerrar y ocultar'),
      ),
    ],
  );

  InputDecoration _decoration(
    String label, {
    String? helper,
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppTheme.dashboardMuted, fontSize: 13),
    helperText: helper,
    helperMaxLines: 2,
    errorMaxLines: 3,
    filled: true,
    fillColor: AppTheme.dashboardBackground.withValues(alpha: .35),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.dashboardLine),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.dashboardBlue, width: 1.5),
    ),
    suffixIcon: suffix,
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSubmitting && _created == null,
    child: _created != null
        ? _successDialog()
        : AlertDialog(
            key: const Key('create_account_dialog'),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            insetPadding: const EdgeInsets.all(16),
            scrollable: true,
            title: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  color: AppTheme.dashboardBlue,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Crear nueva cuenta',
                    style: TextStyle(
                      color: AppTheme.dashboardBlueDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar formulario',
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.dashboardMuted),
                ),
              ],
            ),
            content: SizedBox(
              width: 600,
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Registra el correo de la persona. Generaremos una contraseña inicial segura y te la mostraremos cuando la cuenta se cree correctamente.',
                      style: TextStyle(
                        color: AppTheme.dashboardMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'La contraseña tendrá 24 caracteres con mayúsculas, minúsculas, números y símbolos. Deberás copiarla y compartirla por un medio privado. Crear la cuenta no asigna acceso a una empresa.',
                      style: TextStyle(
                        color: AppTheme.dashboardMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      key: const Key('create_account_email'),
                      controller: _email,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      style: const TextStyle(color: AppTheme.dashboardBlueDark),
                      decoration: _decoration('Correo electrónico'),
                      validator: _validateEmail,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        _error!,
                        key: const Key('create_account_error'),
                        style: const TextStyle(
                          color: AppTheme.dashboardRed,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  key: const Key('create_account_submit'),
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1, size: 20),
                  label: Text(
                    _isSubmitting ? 'Creando cuenta…' : 'Crear cuenta',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dashboardBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
  );
}
