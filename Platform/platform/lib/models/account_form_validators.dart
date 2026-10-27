class AccountFormValidators {
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa el correo electrónico.';
    final parts = email.split('@');
    if (email.length > 254 || parts.length != 2) {
      return 'Ingresa un correo electrónico válido.';
    }
    final local = parts.first;
    final domain = parts.last;
    final labels = domain.split('.');
    if (local.isEmpty ||
        local.length > 64 ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..') ||
        !RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+$").hasMatch(local) ||
        labels.length < 2 ||
        labels.last.length < 2 ||
        labels.any(
          (label) => !RegExp(
            r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$',
          ).hasMatch(label),
        )) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa una contraseña.';
    if (value.runes.length < 14) {
      return 'La contraseña debe tener al menos 14 caracteres.';
    }
    if (value.length > 128) {
      return 'La contraseña no debe superar 128 caracteres.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value) ||
        !RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) {
      return 'Incluye mayúscula, minúscula, número y símbolo.';
    }
    return null;
  }

  static String? confirmation(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirma la contraseña.';
    if (value != password) return 'Las contraseñas no coinciden.';
    return null;
  }
}
