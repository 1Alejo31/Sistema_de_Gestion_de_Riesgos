import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../providers/auth_providers.dart';

/// Validates identity on every protected route entry. No dashboard is built
/// while validation is pending or the local session is unavailable.
class AuthGuard extends ConsumerStatefulWidget {
  const AuthGuard({
    super.key,
    required this.builder,
    this.superAdminOnly = false,
  });
  final bool superAdminOnly;
  final WidgetBuilder builder;

  @override
  ConsumerState<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends ConsumerState<AuthGuard> {
  bool _checking = true;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    // Defer controller notifications until the initial widget build finishes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validate(ref.read(authControllerProvider));
    });
  }

  Future<void> _validate(AuthController auth) async {
    await auth.verifySession();
    if (mounted) setState(() => _checking = false);
  }

  void _redirect([String route = '/login']) {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      _redirect();
    } else if (!_checking) {
      if (auth.passwordChangeRequired) {
        _redirect('/change-password');
      } else if (widget.superAdminOnly && auth.identity?.isSuperAdmin != true) {
        _redirect('/home');
      } else {
        return widget.builder(context);
      }
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
