import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/section_content.dart';
import '../widgets/widget_factory.dart';

class ContactSection extends StatefulWidget {
  final ContactContent content;

  const ContactSection({
    super.key,
    required this.content,
  });

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });

        _nameController.clear();
        _emailController.clear();
        _messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensaje enviado exitosamente. Nos pondremos en contacto pronto.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isSubmitted = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundLight,
            AppTheme.veryLightBlue.withOpacity(0.3),
          ],
        ),
      ),
      child: WidgetFactory.createSectionContainer(
        backgroundColor: Colors.transparent,
        child: WidgetFactory.createContentWrapper(
          maxWidth: 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppTheme.primaryNavy, AppTheme.secondaryBlue],
                ).createShader(bounds),
                child: Text(
                  widget.content.title,
                  style: AppTheme.heading1,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                widget.content.description,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              _buildContactForm(),
              const SizedBox(height: AppTheme.spacingXL),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL * 1.5),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryBlue.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryBlue.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            WidgetFactory.createFormField(
              label: 'Nombre Completo',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            WidgetFactory.createFormField(
              label: 'Correo Electrónico',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su correo';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Por favor ingrese un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
            WidgetFactory.createFormField(
              label: 'Mensaje',
              controller: _messageController,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su mensaje';
                }
                if (value.length < 10) {
                  return 'El mensaje debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingL),
            if (_isSubmitted)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: AppTheme.successGreen,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        '¡Mensaje enviado! Nos pondremos en contacto pronto.',
                        style: AppTheme.bodyRegular.copyWith(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              WidgetFactory.createPrimaryButton(
                text: _isSubmitting ? 'Enviando...' : widget.content.submitButtonText,
                onPressed: _isSubmitting ? () {} : _submitForm,
                isFullWidth: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(
          color: AppTheme.textDark,
          thickness: 1,
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          '© ${DateTime.now().year} SST Platform - Plataforma CRM con IA para Seguridad y Salud en el Trabajo',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textDark.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 16,
              color: AppTheme.secondaryBlue,
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              'Decreto 1072 de 2015 • Resolución 0312 de 2019',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.secondaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
