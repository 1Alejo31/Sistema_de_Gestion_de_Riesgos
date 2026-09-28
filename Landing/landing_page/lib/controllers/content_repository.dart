import 'package:flutter/material.dart';
import '../models/section_content.dart';

/// Repository pattern for content management
/// Centralized data source for all section content
/// Singleton pattern ensures single source of truth
class ContentRepository {
  static final ContentRepository _instance = ContentRepository._internal();

  factory ContentRepository() {
    return _instance;
  }

  ContentRepository._internal();

  /// Get hero section content
  HeroContent getHeroContent() {
    return const HeroContent(
      id: 'hero',
      title: 'GESTIÓN INTELIGENTE DE SEGURIDAD LABORAL',
      subtitle: 'Nuestra plataforma CRM potenciada por IA revoluciona la gestión de SST. Gestione colaboradores, contratistas y stakeholders desde un ecosistema unificado que automatiza, predice y protege en tiempo real.',
      ctaText: 'Explorar Más',
      imagePath: 'assets/images/presentacion agente SST.png',
    );
  }

  /// Get about section content
  AboutContent getAboutContent() {
    return const AboutContent(
      id: 'about',
      title: 'CRM Inteligente: Más Allá de la Gestión Documental Tradicional',
      mission: 'Nuestra plataforma no es otro software de SST: es un CRM (Customer Relationship Management) diseñado para gestionar integralmente la relación con el activo más valioso de su empresa: sus colaboradores. Como un CRM comercial gestiona clientes, nuestra plataforma gestiona empleados, contratistas, proveedores y stakeholders en materia de seguridad y salud. Centralizamos toda la información, interacciones, historial médico, capacitaciones, evaluaciones de riesgo, incidentes y desempeño en SST de cada persona. La IA predice necesidades, personaliza intervenciones, automatiza comunicaciones y genera insights accionables. No más silos de información: una visión 360° de cada colaborador en tiempo real.',
      problem: 'Los sistemas tradicionales de SST son repositorios pasivos de documentos que obligan a equipos humanos a realizar tareas manuales interminables: buscar información dispersa en Excel, emails y carpetas; recordar manualmente vencimientos de exámenes médicos y capacitaciones; consolidar reportes de múltiples fuentes; investigar incidentes sin datos históricos estructurados; gestionar contratistas sin visibilidad de su historial de cumplimiento. El resultado: sobrecarga administrativa, decisiones basadas en datos incompletos, riesgos no detectados a tiempo y cumplimiento reactivo. Las empresas no necesitan más archivadores digitales, necesitan un sistema inteligente que gestione activamente la seguridad de cada persona.',
      approach: 'Nuestra plataforma funciona como el cerebro central de su SG-SST: cada colaborador tiene un perfil dinámico que consolida automáticamente toda su información de SST. La IA monitorea continuamente el estado de cada persona (exámenes médicos vigentes, capacitaciones completadas, exposición a riesgos, historial de incidentes, restricciones médicas) y actúa proactivamente: envía recordatorios personalizados, programa evaluaciones pendientes, identifica trabajadores en riesgo elevado, recomienda capacitaciones específicas según el perfil de riesgo y genera alertas tempranas. Integraciones nativas con sistemas de RRHH, nómina, control de acceso y ERP mantienen datos sincronizados en tiempo real. Dashboards ejecutivos muestran indicadores por persona, área, contratista o toda la organización. Es CRM aplicado a SST: gestión de relaciones basada en datos e inteligencia artificial.',
    );
  }

  /// Get products/services content
  ProductsContent getProductsContent() {
    return const ProductsContent(
      id: 'products',
      title: 'Capacidades CRM para la Gestión Integral de SST',
      description: 'Una plataforma unificada que combina gestión de relaciones, inteligencia artificial y cumplimiento normativo en un solo ecosistema',
      features: [
        ProductFeature(
          title: 'Perfiles 360° de Colaboradores',
          description: 'Como un CRM comercial conoce a cada cliente, SOFÍA conoce a cada colaborador: historial médico completo, capacitaciones realizadas y pendientes, exposición a riesgos específicos, restricciones laborales, incidentes históricos, desempeño en SST y más. La IA predice necesidades individuales (próximo examen médico, capacitación requerida, rotación recomendada) y genera alertas personalizadas. Vista unificada de empleados directos, contratistas, visitantes y proveedores.',
          icon: Icons.person_search,
        ),
        ProductFeature(
          title: 'Automatización de Comunicaciones',
          description: 'Campañas automáticas de comunicación segmentadas por perfil de riesgo, área, cargo o historial: recordatorios de exámenes médicos por vencer, invitaciones a capacitaciones obligatorias, notificaciones de cambios normativos, alertas de inspecciones pendientes. Canales múltiples (email, SMS, WhatsApp, push notifications) con tasas de apertura rastreadas. Seguimiento automático de respuestas y escalamiento de casos sin acción. Como el marketing automation del CRM, pero aplicado a SST.',
          icon: Icons.campaign,
        ),
        ProductFeature(
          title: 'Integraciones Nativas con ERP y RRHH',
          description: 'Conexión bidireccional con SAP, Oracle, SIIGO, Nominapp, Alegra, BUK y principales sistemas de RRHH. Sincronización automática de ingresos, retiros, cambios de cargo, transferencias entre áreas y estructura organizacional. Datos de nómina para cálculo de indicadores. Integración con sistemas de control de acceso (biometría, torniquetes) para monitoreo en tiempo real de quién está en cada área. API REST abierta para conectar cualquier sistema.',
          icon: Icons.integration_instructions,
        ),
        ProductFeature(
          title: 'IA Predictiva y Aprendizaje Continuo',
          description: 'SOFÍA aprende de los datos históricos de su empresa: identifica patrones de accidentalidad por área, turno, hora o actividad; predice probabilidad de incidentes según variables ambientales, carga de trabajo o rotación de personal; recomienda controles específicos basados en efectividad comprobada; optimiza cronogramas de inspecciones según criticidad real. Modelos de machine learning que mejoran con cada interacción, como los sistemas de recomendación del e-commerce aplicados a la prevención.',
          icon: Icons.psychology,
        ),
        ProductFeature(
          title: 'Dashboards Ejecutivos en Tiempo Real',
          description: 'Visualización inteligente de KPIs críticos: índice de frecuencia y severidad de accidentalidad, cumplimiento por estándar de la Resolución 0312, ausentismo por causa médica vs. laboral, efectividad de capacitaciones medida por evaluaciones post-formación, estado de exámenes médicos y certificaciones vigentes, presupuesto ejecutado vs. planificado. Filtros dinámicos por área, cargo, contratista o periodo. Exportación a PDF/Excel programada automáticamente.',
          icon: Icons.dashboard,
        ),
        ProductFeature(
          title: 'Gestión de Contratistas y Proveedores',
          description: 'Registro centralizado de todos los contratistas con sus respectivos sistemas de SST: documentación exigida (afiliaciones ARL, pólizas, certificaciones), evaluación continua de desempeño en seguridad, historial de incidentes por contratista, scoring automático de cumplimiento, alertas de documentos por vencer, aprobaciones de ingreso/renovación basadas en criterios configurables. Control total de terceros desde un módulo especializado, como la gestión de proveedores en un CRM empresarial.',
          icon: Icons.business_center,
        ),
      ],
    );
  }

  /// Get features/how it works content
  FeaturesContent getFeaturesContent() {
    return const FeaturesContent(
      id: 'features',
      title: 'El Ciclo PHVA Inteligente en Acción',
      description: 'Mejora continua automatizada que nunca se detiene. Cada fase del ciclo se ejecuta con precisión milimétrica mientras el sistema aprende y se optimiza.',
      steps: [
        WorkflowStep(
          number: 1,
          title: 'Planear - Estrategia Basada en Datos',
          description: 'SOFÍA recopila y estructura automáticamente toda la información de su empresa: estructura organizacional, procesos productivos, matriz de cargos y perfiles de riesgo. Realiza una evaluación inicial exhaustiva del estado del SG-SST comparándola con estándares de clase mundial. Identifica peligros mediante análisis de puesto de trabajo, inspecciones virtuales con IoT y revisión de históricos. Evalúa riesgos usando matrices probabilísticas avanzadas. Establece objetivos SMART alineados con la estrategia corporativa. Define políticas personalizadas según su sector. Diseña programas de gestión optimizados con asignación inteligente de recursos y presupuestos. Genera automáticamente el plan anual de trabajo con cronogramas realistas.',
          imagePath: 'assets/images/diagrama de etapana planear a nivel general.png',
        ),
        WorkflowStep(
          number: 2,
          title: 'Hacer - Ejecución Sin Fricción',
          description: 'El sistema ejecuta el plan con precisión quirúrgica: programa y gestiona capacitaciones (presenciales, virtuales, microlearning) con seguimiento de asistencia por QR/biometría y evaluación de efectividad. Coordina inspecciones de seguridad con listas de verificación digitales, captura fotográfica geolocalizada y generación automática de planes de acción. Gestiona mantenimientos preventivos y correctivos de equipos críticos. Agenda exámenes médicos ocupacionales (pre-ingreso, periódicos, egreso) con integración a IPS. Investiga accidentes e incidentes con metodología de árbol de causas y genera reportes FURAT automáticos. Prepara brigadas de emergencia con simulacros programados. Asigna responsables con notificaciones push y seguimiento de cumplimiento.',
          imagePath: 'assets/images/Diagrama de el sistema de gestion.png',
        ),
        WorkflowStep(
          number: 3,
          title: 'Verificar - Auditoría Continua Inteligente',
          description: 'Monitoreo 24/7 sin intervención humana: rastrea indicadores de estructura (recursos asignados vs. planificados), proceso (actividades ejecutadas vs. programadas) y resultado (reducción de accidentalidad, ausentismo, clima laboral). Investiga a fondo cada accidente/incidente identificando causas raíz con inteligencia artificial. Audita automáticamente el cumplimiento de los 60 estándares mínimos de la Resolución 0312. Revisa la eficacia del SG-SST comparando desempeño real vs. objetivos con análisis de brechas. Evalúa el cumplimiento legal verificando normativas vigentes en tiempo real. Realiza auditorías internas programadas con evidencias digitales. Prepara empresas para visitas del Ministerio de Trabajo con documentación lista para descarga. Genera dashboards ejecutivos actualizados al minuto.',
          imagePath: 'assets/images/diagrama proceso 1.png',
        ),
        WorkflowStep(
          number: 4,
          title: 'Actuar - Mejora Continua Evolutiva',
          description: 'El sistema no solo reporta problemas, los resuelve: implementa acciones correctivas automáticas para hallazgos menores (actualizaciones de documentos, recordatorios, reasignaciones). Ejecuta acciones preventivas basadas en análisis predictivo de tendencias (identificación de áreas con incremento de reportes de casi-accidentes). Actualiza dinámicamente procesos, procedimientos y estándares según lecciones aprendidas. Modifica la matriz de peligros y riesgos cuando detecta nuevos factores. Optimiza la asignación de recursos económicos, humanos y técnicos usando algoritmos de maximización de impacto. Rediseña programas de capacitación según análisis de efectividad por cargo/tema. Ajusta el plan anual de trabajo en tiempo real ante cambios organizacionales. Mejora continuamente sus propios algoritmos mediante machine learning. El ciclo se retroalimenta de forma autónoma, generando una espiral ascendente de mejora perpetua.',
        ),
      ],
    );
  }

  /// Get contact section content
  ContactContent getContactContent() {
    return const ContactContent(
      id: 'contact',
      title: 'Contáctenos',
      description: '¿Listo para transformar su SG-SST? Déjenos sus datos y nos pondremos en contacto con usted.',
      submitButtonText: 'Enviar Mensaje',
    );
  }
}
