# 🚀 Guía Rápida - Landing Page SOFÍA

## ⚡ Inicio Rápido

### 1️⃣ Instalar Dependencias
```bash
cd "C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page"
flutter pub get
```

### 2️⃣ Ejecutar en Desarrollo
```bash
# Ejecutar en Chrome
flutter run -d chrome

# O ejecutar en Edge
flutter run -d edge
```

### 3️⃣ Ver en el Navegador
- La aplicación se abrirá automáticamente en: `http://localhost:XXXX`
- Hot reload activado: Los cambios se reflejan automáticamente

---

## 🎨 Personalización Rápida

### Cambiar Colores
Edita: `lib/config/app_theme.dart`

```dart
// Ejemplo: Cambiar color primario
static const Color primaryNavy = Color(0xFF1E3A5F); // Tu color aquí
static const Color secondaryBlue = Color(0xFF4A90E2);
```

### Cambiar Textos
Edita: `lib/controllers/content_repository.dart`

```dart
// Ejemplo: Cambiar título hero
HeroContent(
  title: 'Tu nuevo título aquí',
  subtitle: 'Tu nuevo subtítulo',
  ...
)
```

### Agregar/Quitar Secciones
Edita: `lib/main.dart`

```dart
// Comenta/descomenta secciones
Column(
  children: [
    HeroSection(...),           // ✅ Siempre visible
    ServicesCardsSection(),    // ✅ Nueva sección
    StatsSection(),            // ✅ Estadísticas
    // AboutSection(...),      // ❌ Comentar para ocultar
    ProductsSection(...),      // ✅ Visible
    ...
  ],
)
```

---

## 📦 Compilar para Producción

### Compilar Web
```bash
# Compilación optimizada
flutter build web --release

# Los archivos estarán en: build/web/
```

### Compilar con CanvasKit (mejor rendimiento)
```bash
flutter build web --release --web-renderer canvaskit
```

### Compilar con HTML (mejor compatibilidad)
```bash
flutter build web --release --web-renderer html
```

---

## 🌐 Deployment

### Opción 1: Firebase Hosting (Recomendado)
```bash
# 1. Instalar Firebase CLI
npm install -g firebase-tools

# 2. Login
firebase login

# 3. Inicializar proyecto
firebase init hosting

# 4. Compilar
flutter build web --release

# 5. Deploy
firebase deploy --only hosting
```

### Opción 2: GitHub Pages
```bash
# 1. Compilar
flutter build web --release --base-href "/nombre-repo/"

# 2. Copiar build/web/ a tu repo
# 3. Push a GitHub
# 4. Activar GitHub Pages en Settings
```

### Opción 3: Netlify
1. Compilar: `flutter build web --release`
2. Arrastra `build/web/` a Netlify Drop
3. ¡Listo!

### Opción 4: Vercel
```bash
# 1. Instalar Vercel CLI
npm i -g vercel

# 2. Compilar
flutter build web --release

# 3. Deploy
cd build/web
vercel
```

---

## 🐛 Solución de Problemas

### Error: "google_fonts package not found"
```bash
flutter pub get
flutter clean
flutter pub get
```

### Error: "Hot reload not working"
```bash
# Reiniciar
r (en la terminal donde corre flutter)

# O detener y reiniciar
flutter run -d chrome
```

### Página en blanco al compilar
```bash
# Asegúrate de tener el base-href correcto
flutter build web --release --base-href "/"
```

### Imágenes no cargan
- Verifica que las imágenes estén en `assets/images/`
- Revisa `pubspec.yaml`: debe tener `assets: - assets/images/`

---

## 📱 Probar en Dispositivos

### Desktop
```bash
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run -d linux    # Linux
```

### Mobile (requiere emuladores instalados)
```bash
flutter run -d android  # Android
flutter run -d ios      # iOS
```

---

## 🔧 Configuración Opcional

### Cambiar Puerto de Desarrollo
```bash
flutter run -d chrome --web-port=8080
```

### Activar Source Maps (debugging)
```bash
flutter run -d chrome --source-maps
```

### Ver en Red Local (acceder desde otros dispositivos)
```bash
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
# Acceder desde: http://TU_IP:8080
```

---

## 📊 Performance

### Optimizar Tamaño
```bash
# Compilar con tree-shaking
flutter build web --release --tree-shake-icons

# Análisis de tamaño
flutter build web --release --analyze-size
```

### Lazy Loading de Rutas
```dart
// En main.dart, usar MaterialApp.router
// con lazy loading de páginas
```

---

## 🎯 Checklist Pre-Producción

Antes de lanzar, verifica:

- [ ] Todos los textos están correctos (sin "Lorem ipsum")
- [ ] Links de navegación funcionan
- [ ] Formulario de contacto funciona
- [ ] Imágenes cargan correctamente
- [ ] Responsive en mobile/tablet/desktop
- [ ] No hay console errors
- [ ] Favicon actualizado (`web/favicon.png`)
- [ ] Title y meta tags configurados (`web/index.html`)
- [ ] Analytics integrado (Google Analytics, etc.)
- [ ] Performance optimizado (Lighthouse score >90)

---

## 📈 Analytics (Opcional)

### Google Analytics
1. Edita `web/index.html`
2. Agrega script de GA antes de `</head>`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

---

## 🔐 SEO Básico

Edita `web/index.html`:

```html
<head>
  <!-- Title -->
  <title>SOFÍA - Plataforma CRM con IA para SST</title>
  
  <!-- Meta Description -->
  <meta name="description" content="Plataforma CRM con Inteligencia Artificial para la gestión de Seguridad y Salud en el Trabajo. Automatización, cumplimiento y prevención.">
  
  <!-- Keywords -->
  <meta name="keywords" content="CRM SST, seguridad laboral, salud ocupacional, inteligencia artificial, SOFÍA, Colombia">
  
  <!-- Open Graph (Facebook, LinkedIn) -->
  <meta property="og:title" content="SOFÍA - Plataforma CRM con IA para SST">
  <meta property="og:description" content="Gestión inteligente de Seguridad y Salud en el Trabajo">
  <meta property="og:image" content="URL_DE_TU_IMAGEN">
  
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="SOFÍA - Plataforma CRM con IA para SST">
  <meta name="twitter:description" content="Gestión inteligente de Seguridad y Salud en el Trabajo">
</head>
```

---

## 📞 Soporte

**¿Necesitas ayuda?**
- 📧 Dudas técnicas: Pregúntame
- 🐛 Bugs: Reporta aquí
- 💡 Nuevas features: Sugerencias bienvenidas

---

## 🎉 ¡Todo Listo!

Tu landing page está lista para:
- ✅ Desarrollo local
- ✅ Pruebas
- ✅ Deploy a producción
- ✅ Impresionar clientes

**Comando rápido para empezar**:
```bash
flutter run -d chrome
```

---

**Última actualización**: 2026-09-20
**Versión**: 2.0.0 (Rediseño completo)
