# 🚀 Despliegue en Firebase Hosting

## ✅ PASO 1: COMPILACIÓN - COMPLETADO

La aplicación ya está compilada en `build/web/`

---

## 📋 PASO 2: LOGIN A FIREBASE

Abre tu terminal (PowerShell o CMD) y ejecuta:

```bash
cd "C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page"
firebase login
```

Esto abrirá tu navegador para que inicies sesión con tu cuenta de Google.

---

## 🔧 PASO 3: INICIALIZAR FIREBASE

Después del login, ejecuta:

```bash
firebase init hosting
```

**Respuestas a las preguntas:**

1. **"Please select an option:"** 
   - Si tienes proyecto: `Use an existing project`
   - Si no: `Create a new project`

2. **"What do you want to use as your public directory?"**
   ```
   build/web
   ```

3. **"Configure as a single-page app (rewrite all urls to /index.html)?"**
   ```
   y (Yes)
   ```

4. **"Set up automatic builds and deploys with GitHub?"**
   ```
   N (No)
   ```

5. **"File build/web/index.html already exists. Overwrite?"**
   ```
   N (No)
   ```

---

## 🚀 PASO 4: DESPLEGAR

Una vez configurado, ejecuta:

```bash
firebase deploy --only hosting
```

---

## 📝 RESUMEN DE COMANDOS

```bash
# 1. Navegar al proyecto
cd "C:\Users\alejo\OneDrive\Documentos\Sistema de Gestion de Riesgos\Landing\landing_page"

# 2. Login
firebase login

# 3. Inicializar
firebase init hosting
# - Public directory: build/web
# - Single-page app: Yes
# - GitHub deploys: No
# - Overwrite index.html: No

# 4. Desplegar
firebase deploy --only hosting
```

---

## 🎯 DESPUÉS DEL DEPLOY

Firebase te dará una URL como:
```
https://tu-proyecto.web.app
```
o
```
https://tu-proyecto.firebaseapp.com
```

---

## 🔄 PARA ACTUALIZAR EN EL FUTURO

Cuando hagas cambios:

```bash
# 1. Compilar nuevamente
flutter build web --release

# 2. Desplegar
firebase deploy --only hosting
```

---

## 📊 VER ESTADÍSTICAS

```bash
# Ver hosting info
firebase hosting:channel:list

# Ver proyectos
firebase projects:list
```

---

## ⚙️ CONFIGURACIÓN CREADA

Después de `firebase init`, se crearán:
- `.firebaserc` - Configuración del proyecto
- `firebase.json` - Configuración de hosting
- `.firebase/` - Carpeta de cache (ignorar en git)

---

## 🆓 PLAN GRATUITO

Firebase Hosting gratuito incluye:
- ✅ 10 GB de almacenamiento
- ✅ 360 MB/día de transferencia
- ✅ SSL gratis
- ✅ CDN global
- ✅ Dominio personalizado

---

## 🌐 DOMINIO PERSONALIZADO (Opcional)

Si quieres usar tu propio dominio:

```bash
firebase hosting:channel:deploy production
```

Luego en la consola de Firebase:
1. Ve a Hosting
2. Click "Add custom domain"
3. Sigue las instrucciones

---

**¡Ejecuta los comandos paso a paso y me avisas cuando termines!** 🚀
