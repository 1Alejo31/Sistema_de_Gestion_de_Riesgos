import 'package:flutter/material.dart';
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SST - Plataforma CRM con IA para Seguridad y Salud en el Trabajo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().themeData,
      home: const LandingPage(),
      routes: {
        '/login': (context) => const LoginPage(),
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
    return Container(
      key: key,
      child: child,
    );
  }
}
