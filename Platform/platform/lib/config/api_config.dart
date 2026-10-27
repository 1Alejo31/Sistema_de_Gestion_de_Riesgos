import 'package:flutter/foundation.dart';

/// Public configuration only. No credentials belong in dart-define values.
class ApiConfig {
  /// Shared API origin for every application service and build mode.
  static const apiBaseUrl = 'http://3.148.192.204/';

  ApiConfig(
    String value, {
    bool allowLocalHttp = false,
    bool allowDevelopmentHttp = false,
  }) {
    final uri = Uri.tryParse(value.trim());
    final local =
        uri != null &&
        ['localhost', '127.0.0.1', '[::1]', '::1'].contains(uri.host);
    final configuredApi =
        uri != null &&
        uri.scheme == 'http' &&
        uri.hasAuthority &&
        uri.origin == Uri.parse(apiBaseUrl).origin;
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                (configuredApi ||
                    (!kReleaseMode &&
                        ((local && allowLocalHttp) ||
                            allowDevelopmentHttp)))))) {
      throw const FormatException('Configuración de API no válida.');
    }
    baseUri = uri.replace(path: '');
  }

  // Retained for existing callers. Build flags cannot replace the shared origin.
  factory ApiConfig.fromEnvironment() => ApiConfig(apiBaseUrl);

  /// Startup and Riverpod use the same origin, without local asset fallbacks.
  static Future<ApiConfig> loadForStartup() async =>
      ApiConfig.fromEnvironment();

  late final Uri baseUri;

  Uri endpoint(String path) {
    final relative = Uri.tryParse(path);
    if (relative == null ||
        relative.hasScheme ||
        relative.hasAuthority ||
        relative.hasQuery ||
        relative.hasFragment ||
        !RegExp(r'^/api/v1/[A-Za-z0-9_/-]+$').hasMatch(path)) {
      throw const FormatException('Ruta de API no válida.');
    }
    return baseUri.resolve(path);
  }
}
