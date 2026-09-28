import 'package:flutter/material.dart';

/// Controller for landing page navigation and state management
/// Follows Controller pattern in MVC architecture
class LandingPageController extends ChangeNotifier {
  // Scroll controller for smooth navigation
  final ScrollController scrollController = ScrollController();

  // Global keys for each section
  final GlobalKey heroKey = GlobalKey();
  final GlobalKey aboutKey = GlobalKey();
  final GlobalKey productsKey = GlobalKey();
  final GlobalKey featuresKey = GlobalKey();
  final GlobalKey contactKey = GlobalKey();

  // Current visible section (for navbar highlighting)
  String _currentSection = 'inicio';
  String get currentSection => _currentSection;

  // Mobile menu state
  bool _isMobileMenuOpen = false;
  bool get isMobileMenuOpen => _isMobileMenuOpen;

  void toggleMobileMenu() {
    _isMobileMenuOpen = !_isMobileMenuOpen;
    notifyListeners();
  }

  void closeMobileMenu() {
    if (_isMobileMenuOpen) {
      _isMobileMenuOpen = false;
      notifyListeners();
    }
  }

  /// Scroll to a specific section smoothly
  void scrollToSection(String sectionId) {
    GlobalKey? targetKey;

    switch (sectionId) {
      case 'inicio':
        targetKey = heroKey;
        break;
      case 'nosotros':
        targetKey = aboutKey;
        break;
      case 'productos':
        targetKey = productsKey;
        break;
      case 'caracteristicas':
        targetKey = featuresKey;
        break;
      case 'contacto':
        targetKey = contactKey;
        break;
    }

    if (targetKey?.currentContext != null) {
      final context = targetKey!.currentContext!;
      final renderBox = context.findRenderObject() as RenderBox?;

      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero).dy;
        final currentScroll = scrollController.offset;
        final targetScroll = currentScroll + position - 80; // Offset for navbar

        scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );

        _currentSection = sectionId;
        closeMobileMenu();
        notifyListeners();
      }
    }
  }

  /// Update current section based on scroll position
  void updateCurrentSection(String sectionId) {
    if (_currentSection != sectionId) {
      _currentSection = sectionId;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
