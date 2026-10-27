import 'package:flutter/material.dart';

/// Base model for section content
/// Follows Model pattern in MVC architecture
abstract class SectionContent {
  final String id;
  final String title;

  const SectionContent({required this.id, required this.title});
}

/// Hero section content model
class HeroContent extends SectionContent {
  final String subtitle;
  final String ctaText;
  final String? imagePath;

  const HeroContent({
    required super.id,
    required super.title,
    required this.subtitle,
    required this.ctaText,
    this.imagePath,
  });
}

/// About section content model
class AboutContent extends SectionContent {
  final String mission;
  final String problem;
  final String approach;

  const AboutContent({
    required super.id,
    required super.title,
    required this.mission,
    required this.problem,
    required this.approach,
  });
}

/// Product/Service feature model
class ProductFeature {
  final String title;
  final String description;
  final IconData icon;

  const ProductFeature({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Products section content model
class ProductsContent extends SectionContent {
  final String description;
  final List<ProductFeature> features;

  const ProductsContent({
    required super.id,
    required super.title,
    required this.description,
    required this.features,
  });
}

/// How it works step model
class WorkflowStep {
  final int number;
  final String title;
  final String description;
  final String? imagePath;

  const WorkflowStep({
    required this.number,
    required this.title,
    required this.description,
    this.imagePath,
  });
}

/// Features/How it works section content model
class FeaturesContent extends SectionContent {
  final String description;
  final List<WorkflowStep> steps;

  const FeaturesContent({
    required super.id,
    required super.title,
    required this.description,
    required this.steps,
  });
}

/// Contact form field model
class ContactFormData {
  String name;
  String email;
  String message;

  ContactFormData({this.name = '', this.email = '', this.message = ''});

  bool get isValid {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        email.contains('@') &&
        message.isNotEmpty;
  }
}

/// Contact section content model
class ContactContent extends SectionContent {
  final String description;
  final String submitButtonText;

  const ContactContent({
    required super.id,
    required super.title,
    required this.description,
    required this.submitButtonText,
  });
}
