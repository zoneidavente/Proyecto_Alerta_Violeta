# Publicar Alerta Violeta

La arquitectura de publicación es:

- Flutter Web en Firebase Hosting (enlace HTTPS público).
- API Express en Render.
- Datos persistentes en MongoDB Atlas.

La URI de Atlas solo se configura como variable secreta en Render. Nunca se
incluye en Flutter, Firebase Hosting ni en este repositorio.

## 1. MongoDB Atlas

1. Crea un clúster y un usuario de base de datos con los permisos mínimos
   necesarios.
2. Copia la URI de conexión `mongodb+srv://...` y selecciona la base `acoso_cali`.
   Codifica los caracteres especiales de la contraseña para URI.
3. En **Network Access**, permite las conexiones de Render. Si no tienes una
   lista de IP salientes fija para el servicio, Atlas puede requerir `0.0.0.0/0`;
   en ese caso usa una contraseña larga, única y con permisos mínimos.

## 2. API en Render

1. Sube estos cambios a GitHub y en Render crea un **Blueprint** apuntando al
   repositorio y al archivo `render.yaml` de la raíz.
2. Render pedirá el valor de `MONGODB_URI`; pega la URI de Atlas. No la publiques
   en archivos ni en el cliente Flutter.
3. Espera a que el servicio termine el despliegue. Comprueba
   `https://proyecto-alerta-violeta.onrender.com/health`: debe responder
   `{"status":"ok"}`. Render proporciona el puerto mediante `PORT`.

El nombre `proyecto-alerta-violeta` debe estar disponible en Render para usar esa
URL. Si asignas otro nombre, usa el dominio HTTPS que te proporcione Render al
compilar la web.

## 3. Web en Firebase Hosting

Instala Flutter y Firebase CLI, inicia sesión con una cuenta que tenga acceso al
proyecto `alerta-violeta-b6d28` y ejecuta desde la carpeta `login_app`:

```powershell
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://proyecto-alerta-violeta.onrender.com
firebase use alerta-violeta-b6d28
firebase deploy --only hosting
```

Si tu API tiene otro dominio, reemplaza la URL en `API_BASE_URL`. Firebase
imprimirá el enlace HTTPS público al finalizar. La configuración de Hosting
redirige las rutas web de Flutter a `index.html`.

Para probar localmente contra la API publicada:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://proyecto-alerta-violeta.onrender.com
```

## Verificación

Abre el enlace de Firebase y prueba registro, inicio de sesión, envío de reporte y
alerta SOS. La ubicación del navegador requiere permiso y un contexto seguro
(HTTPS o `localhost`). Revisa los documentos creados en Atlas y los logs de
Render. El backend conserva la configuración predeterminada del pool de Mongoose;
no se fijan límites arbitrarios sin conocer concurrencia y capacidad del clúster.