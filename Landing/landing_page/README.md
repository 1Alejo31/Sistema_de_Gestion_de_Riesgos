# SOFÍA SG-SST - Landing Page

Landing page profesional para el Sistema de Gestión de Riesgos Psicosociales (batería de riesgo psicosocial).

## 📋 Descripción

Esta es una landing page moderna y profesional construida con Flutter para web, que presenta el sistema **SOFÍA** - un Agente Inteligente para la Gestión de Seguridad y Salud en el Trabajo (SG-SST) basado en inteligencia artificial.

### Propuesta de Valor

SOFÍA es un Director Virtual del SG-SST que transforma la gestión de seguridad y salud laboral mediante:
- 🤖 Agente inteligente que analiza, comprende, decide y actúa
- 🔄 Automatización basada en el ciclo PHVA (Planear-Hacer-Verificar-Actuar)
- 📊 Integración completa con ERP, RRHH, documentos, IoT y sensores
- ✅ Cumplimiento normativo (Decreto 1072 de 2015 y Resolución 0312 de 2019)
- 📈 Análisis de datos y reportería en tiempo real

## 🏗️ Arquitectura

El proyecto sigue el patrón **MVC (Model-View-Controller)** con clara separación de responsabilidades:

```
lib/
├── config/           # Configuración de la app (Singleton)
│   └── app_theme.dart
├── models/           # Modelos de datos
│   └── section_content.dart
├── controllers/      # Lógica de negocio y estado
│   ├── page_controller.dart
│   └── content_repository.dart
├── views/            # Componentes visuales por sección
│   ├── hero_section.dart
│   ├── about_section.dart
│   ├── products_section.dart
│   ├── features_section.dart
│   └── contact_section.dart
├── widgets/          # Componentes reutilizables (Factory)
│   ├── widget_factory.dart
│   └── navbar.dart
└── main.dart         # Punto de entrada
```

## 🎨 Patrones de Diseño Implementados

### 1. **Singleton Pattern**
- **Archivo**: `lib/config/app_theme.dart`
- **Propósito**: Garantiza una única instancia del tema de la aplicación
- **Por qué**: Centraliza la configuración de colores, tipografía y estilos, evitando duplicación y asegurando consistencia visual en toda la app

### 2. **Factory Pattern**
- **Archivo**: `lib/widgets/widget_factory.dart`
- **Propósito**: Crea widgets reutilizables con configuración consistente
- **Por qué**: Facilita la creación de botones, cards, formularios y otros componentes con estilos uniformes, reduciendo código repetitivo y mejorando mantenibilidad

### 3. **Repository Pattern**
- **Archivo**: `lib/controllers/content_repository.dart`
- **Propósito**: Centraliza el acceso a los datos de contenido
- **Por qué**: Separa la lógica de obtención de datos de la UI, facilitando futuros cambios (ej: migrar de datos estáticos a API) sin afectar las vistas

### 4. **MVC (Model-View-Controller)**
- **Models**: Definen la estructura de datos (`section_content.dart`)
- **Views**: Componentes visuales puros que reciben datos (`*_section.dart`)
- **Controllers**: Gestionan estado, navegación y lógica (`page_controller.dart`)
- **Por qué**: Separación de responsabilidades clara, testeable y escalable

### 5. **Observer Pattern** (via ChangeNotifier)
- **Archivo**: `lib/controllers/page_controller.dart`
- **Propósito**: Notifica cambios de estado a los widgets suscritos
- **Por qué**: Permite actualización reactiva de la UI cuando cambia el estado (sección activa, menú móvil)

## 🎯 Estructura de Secciones

La landing page contiene **5 secciones principales**:

1. **INICIO (Hero)** - Título impactante, subtítulo, CTA y presentación de SOFÍA
2. **QUIÉNES SOMOS** - Misión, problema que resuelve, enfoque diferencial
3. **QUÉ HACEMOS / PRODUCTOS** - Características del sistema (6 módulos principales)
4. **CARACTERÍSTICAS / CÓMO FUNCIONA** - Ciclo PHVA en 4 pasos
5. **CONTÁCTENOS** - Formulario de contacto y footer

## 🎨 Sistema de Diseño

### Paleta de Colores (Corporativa SST)
- **Primary Navy**: `#1A3A5C` - Azul marino profundo (confianza, estabilidad)
- **Secondary Blue**: `#2E6BA6` - Azul corporativo (tecnología)
- **Success Green**: `#4CAF50` - Verde seguridad (salud, cumplimiento)
- **Background Light**: `#F5F7FA` - Gris muy claro (fondos)
- **Text Dark**: `#2C3E50` - Gris carbón (textos)
- **Accent Orange**: `#FF9800` - Naranja alerta (CTAs)

### Tipografía
- **Familia**: Inter (Google Fonts)
- **Pesos**: Regular (400), Medium (500), SemiBold (600), Bold (700), ExtraBold (800)
- **Escala**: 14px → 16px → 20px → 28px → 42px → 56px (hero)

### Principios de Diseño
- ✅ Profesional sin ser genérico
- ✅ Confianza técnica (sistema legal + salud laboral)
- ✅ Movimiento intencional (fade-in en hero, sin efectos excesivos)
- ✅ Jerarquía clara (CTAs destacados, acciones secundarias outline)
- ❌ Evita templates AI-generados (cream backgrounds, terracotta, cards genéricas)

## 🚀 Cómo Ejecutar el Proyecto

### Prerrequisitos
- Flutter SDK 3.12.2 o superior
- Navegador web (Chrome recomendado)

### Instalación

1. **Navegar al directorio del proyecto**:
   ```bash
   cd landing_page
   ```

2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

3. **Ejecutar en modo web (Chrome)**:
   ```bash
   flutter run -d chrome
   ```

4. **Ejecutar en modo web (servidor local)**:
   ```bash
   flutter run -d web-server --web-port=8080
   ```
   Luego abre: `http://localhost:8080`

### Compilar para Producción

Para generar los archivos de producción optimizados:

```bash
flutter build web --release
```

Los archivos compilados estarán en `build/web/`

## 📱 Responsive Design

La landing page es completamente responsive:
- **Desktop** (≥768px): Layout de 2 columnas, grid de 3 columnas para productos
- **Mobile** (<768px): Layout de 1 columna, stack vertical, menú hamburguesa

## 🔧 Tecnologías Utilizadas

- **Flutter** 3.12.2+
- **Dart** 3.0+
- **Google Fonts** 6.3.3 - Tipografía Inter
- **Material Design** - Sistema de componentes base

## 📦 Assets

Los assets (imágenes de la documentación) se encuentran en:
- `assets/images/Diagrama de el sistema de gestion.png`
- `assets/images/diagrama de etapana planear a nivel general.png`
- `assets/images/diagrama proceso 1.png`
- `assets/images/presentacion agente SST.png`

## 📝 Notas de Desarrollo

- **NO incluye precios ni planes de pago** (requisito del cliente)
- **Formulario de contacto**: Actualmente simula envío (await 2s), listo para integrar con backend
- **Navegación suave**: Animación de scroll entre secciones (800ms easeInOut)
- **Animaciones**: Fade-in/slide-up en hero section para presentación profesional

## 🎓 Aprendizajes del Proyecto

Este proyecto demuestra:
1. Implementación práctica de patrones de diseño en Flutter
2. Arquitectura MVC escalable y mantenible
3. Sistema de diseño cohesivo y profesional
4. Responsive design sin frameworks externos
5. Gestión de estado con ChangeNotifier
6. Factory pattern para componentes reutilizables

## 📄 Licencia

Proyecto privado - Sistema de Gestión de Riesgos Psicosociales

---

**Desarrollado con Flutter** 💙
