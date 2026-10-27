import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = ref.read(authControllerProvider);
    if (auth.isBusy || !_formKey.currentState!.validate()) return;
    final success = await auth.login(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    _passwordController.clear();
    if (success && auth.isAuthenticated) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        auth.passwordChangeRequired ? '/change-password' : '/home',
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 1000 && size.height >= 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundGradientStart,
              AppTheme.veryLightBlue,
              AppTheme.white,
            ],
          ),
        ),
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Lado izquierdo - Imagen y branding
        Expanded(flex: 5, child: _buildBrandingSide()),
        // Lado derecho - Formulario de login
        Expanded(flex: 5, child: _buildLoginForm()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 360, child: _buildBrandingSide()),
          _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildBrandingSide() {
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 1000 || size.height < 600;
    return Container(
      padding: EdgeInsets.all(mobile ? 20 : 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Título
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.psychology, size: 32, color: AppTheme.white),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  'SST Platform',
                  style: TextStyle(
                    fontSize: mobile ? 24 : 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: mobile ? 12 : 40),

          // Imagen del agente inteligente - Ampliada y difuminada
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 0.7, 0.85, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/agente_inteligente_mision.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.secondaryBlue.withValues(alpha: 0.2),
                            AppTheme.lightBlue.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.health_and_safety,
                          size: 120,
                          color: AppTheme.secondaryBlue.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Texto descriptivo
          Text(
            'Gestión Inteligente de SST',
            style: TextStyle(
              fontSize: mobile ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tu aliado experto en Seguridad y Salud en el Trabajo',
            style: TextStyle(
              fontSize: mobile ? 14 : 16,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    final auth = ref.watch(authStateProvider);
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 1000 || size.height < 600;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 16 : 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: EdgeInsets.all(mobile ? 24 : 40),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Accede a tu plataforma SST',
                  style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (auth.notice != null) ...[
                  Text(
                    auth.notice!,
                    key: const Key('auth_notice'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                if (auth.failure != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      auth.failure!.supportMessage,
                      key: const Key('auth_error'),
                      style: const TextStyle(color: AppTheme.dashboardRed),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Campo Email
                TextFormField(
                  key: const Key('login_email'),
                  controller: _emailController,
                  enabled: !auth.isBusy,
                  autofillHints: const [AutofillHints.username],
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    hintText: 'tu@empresa.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.secondaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.secondaryBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundLight,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese su correo';
                    }
                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value.trim())) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Contraseña
                TextFormField(
                  key: const Key('login_password'),
                  controller: _passwordController,
                  enabled: !auth.isBusy,
                  autofillHints: const [AutofillHints.password],
                  enableSuggestions: false,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _handleLogin(),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: '••••••••',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppTheme.secondaryBlue,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.secondaryBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundLight,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Botón de Login
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryBlue.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    key: const Key('login_submit'),
                    onPressed: auth.isBusy ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: auth.isBusy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'Procesando acceso',
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.cardBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'O',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.cardBorder)),
                  ],
                ),
                const SizedBox(height: 24),

                // Botón Volver a inicio
                OutlinedButton(
                  onPressed: auth.isBusy
                      ? null
                      : () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (_) => false,
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryBlue,
                    side: BorderSide(color: AppTheme.secondaryBlue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Volver al Inicio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Texto de ayuda
                Text(
                  '¿No tienes una cuenta?',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: auth.isBusy
                      ? null
                      : () {
                          // TODO: Navegar a página de contacto/registro
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (_) => false,
                          );
                        },
                  child: Text(
                    'Contacta con ventas',
                    style: TextStyle(
                      color: AppTheme.secondaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
