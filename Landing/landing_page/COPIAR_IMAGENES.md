# 📸 Instrucciones para Copiar Imágenes

## ✅ PASO 1: Copiar las Imágenes

Necesitas copiar 2 imágenes a la carpeta `assets/images/`:

### Imagen 1 - Hero Section
**Origen:**
```
C:\Users\alejo\OneDrive\Imágenes\c2c60fb6-f0bc-4869-8e20-b776815ad98d.png
```

**Destino:**
```
C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page\assets\images\profesional_sst_hero.png
```

### Imagen 2 - Nuestra Misión
**Origen:**
```
C:\Users\alejo\OneDrive\Imágenes\415cd158-f6cc-4061-8385-3fed20e524c3.png
```

**Destino:**
```
C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page\assets\images\agente_inteligente_mision.png
```

---

## 🖱️ Cómo Copiarlas (Windows)

### Opción 1: Explorador de Archivos

1. Abre el Explorador de Windows
2. Ve a `C:\Users\alejo\OneDrive\Imágenes\`
3. Copia `c2c60fb6-f0bc-4869-8e20-b776815ad98d.png`
4. Ve a `C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page\assets\images\`
5. Pega y renombra a `profesional_sst_hero.png`
6. Repite con la segunda imagen

### Opción 2: Comando PowerShell

Abre PowerShell y ejecuta:

```powershell
# Crear carpeta assets/images si no existe
New-Item -ItemType Directory -Force -Path "C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page\assets\images"

# Copiar imagen 1 (Hero)
Copy-Item "C:\Users\alejo\OneDrive\Imágenes\c2c60fb6-f0bc-4869-8e20-b776815ad98d.png" "C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page\assets\images\profesional_sst_hero.png"

# Copiar imagen 2 (Misión)
Copy-Item "C:\Users\alejo\OneDrive\Imágenes\415cd158-f6cc-4061-8385-3fed20e524c3.png" "C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page\assets\images\agente_inteligente_mision.png"
```

---

## ✅ PASO 2: Verificar

Después de copiar, verifica que existan:

```
landing_page/
  assets/
    images/
      ✓ profesional_sst_hero.png
      ✓ agente_inteligente_mision.png
```

---

## 🚀 PASO 3: Ejecutar

Una vez copiadas las imágenes:

```bash
cd "C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page"
flutter run -d chrome
```

---

## 📝 QUÉ SE ACTUALIZÓ EN EL CÓDIGO

### Hero Section (`hero_section.dart`)
- ✅ Cambiado de `Image.network()` a `Image.asset()`
- ✅ Ruta: `'assets/images/profesional_sst_hero.png'`
- ✅ Imagen: Profesional SST con chaleco azul

### About Section (`about_section.dart`)
- ✅ Primera imagen ("Nuestra Misión")
- ✅ Cambiado de URL Unsplash a asset local
- ✅ Ruta: `'assets/images/agente_inteligente_mision.png'`
- ✅ Imagen: "LA SOLUCIÓN - Agente Inteligente SG-SST IA"

---

## ⚠️ IMPORTANTE

El archivo `pubspec.yaml` ya tiene configurado:

```yaml
flutter:
  assets:
    - assets/images/
```

Esto permite que Flutter cargue las imágenes desde la carpeta `assets/images/`.

---

## 🎨 RESULTADO FINAL

**Hero Section:** Mostrará la profesional SST con chaleco azul y fondo con iconos de seguridad

**Nuestra Misión:** Mostrará la imagen con texto "LA SOLUCIÓN" y características del agente IA

---

**¡Después de copiar las imágenes, ejecuta `flutter run -d chrome` para verlas!** 🎉
