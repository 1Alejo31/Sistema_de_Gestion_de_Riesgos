import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/api_config.dart';
import 'controllers/auth_controller.dart';
import 'providers/auth_providers.dart';
import 'widgets/auth_guard.dart';
import 'config/app_theme.dart';
import 'controllers/page_controller.dart';
import 'controllers/content_repository.dart';
import 'widgets/navbar.dart';
import 'views/hero_section.dart';
import 'views/services_cards_section.dart';
import 'views/stats_section.dart';
import 'views/about_section.dart';
import 'views/products_section.dart';
import 'views/features_section.dart';
import 'views/contact_section.dart';
import 'views/login_page.dart';
import 'views/home_page.dart';
import 'views/change_password_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await ApiConfig.loadForStartup();
  runApp(MyApp(apiConfig: config));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.authController,
    this.apiConfig,
    this.initialRoute,
    this.theme,
  });

  final AuthController? authController;
  final ApiConfig? apiConfig;
  final String? initialRoute;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      if (apiConfig != null) apiConfigProvider.overrideWithValue(apiConfig),
      if (authController != null)
        authControllerProvider.overrideWithValue(authController!),
    ],
    child: _App(initialRoute: initialRoute, theme: theme),
  );
}

class _App extends ConsumerStatefulWidget {
  const _App({this.initialRoute, this.theme});
  final String? initialRoute;
  final ThemeData? theme;

  @override
  ConsumerState<_App> createState() => _AppState();
}

class _AppState extends ConsumerState<_App> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !ref.read(authStateProvider).isAuthenticated) {
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (_) => false,
            );
          }
        });
      }
    });
    final routes = <String, WidgetBuilder>{
      '/': (_) => const LandingPage(),
      '/login': (_) => const LoginPage(),
      '/home': (_) => AuthGuard(builder: (_) => const HomePage()),
      '/company-information': (_) =>
          AuthGuard(builder: (_) => const HomePage()),
      '/change-password': (_) => const ChangePasswordPage(),
      '/accounts': (_) =>
          AuthGuard(superAdminOnly: true, builder: (_) => const HomePage()),
      '/organizations': (_) =>
          AuthGuard(superAdminOnly: true, builder: (_) => const HomePage()),
    };
    return MaterialApp(
      navigatorKey: _navigatorKey,
      initialRoute: widget.initialRoute,
      title: 'SST - Plataforma CRM con IA para Seguridad y Salud en el Trabajo',
      debugShowCheckedModeBanner: false,
      theme: widget.theme ?? AppTheme().themeData,
      routes: routes,
      onGenerateInitialRoutes: (name) {
        final route = routes.containsKey(name) ? name : '/';
        return [
          MaterialPageRoute<void>(
            settings: RouteSettings(name: route),
            builder: routes[route]!,
          ),
        ];
      },
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final LandingPageController _pageController;
  late final ContentRepository _contentRepository;

  @override
  void initState() {
    super.initState();
    _pageController = LandingPageController();
    _contentRepository = ContentRepository();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _pageController.scrollController,
            child: Column(
              children: [
                const SizedBox(height: 80),
                _buildSection(
                  key: _pageController.heroKey,
                  child: HeroSection(
                    content: _contentRepository.getHeroContent(),
                    controller: _pageController,
                  ),
                ),
                const ServicesCardsSection(),
                const StatsSection(),
                _buildSection(
                  key: _pageController.aboutKey,
                  child: AboutSection(
                    content: _contentRepository.getAboutContent(),
                  ),
                ),
                _buildSection(
                  key: _pageController.productsKey,
                  child: ProductsSection(
                    content: _contentRepository.getProductsContent(),
                  ),
                ),
                _buildSection(
                  key: _pageController.featuresKey,
                  child: FeaturesSection(
                    content: _contentRepository.getFeaturesContent(),
                  ),
                ),
                _buildSection(
                  key: _pageController.contactKey,
                  child: ContactSection(
                    content: _contentRepository.getContactContent(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ListenableBuilder(
              listenable: _pageController,
              builder: (context, child) {
                return Navbar(controller: _pageController);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required GlobalKey key, required Widget child}) {
    return Container(key: key, child: child);
  }
}
