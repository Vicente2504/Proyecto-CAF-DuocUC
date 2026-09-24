# CAF Movimiento — Plataforma de Evaluación de Movimiento Funcional

Plataforma para el **Centro de Acondicionamiento Físico (CAF) de Duoc UC
Plaza Vespucio**: los instructores evalúan la técnica de los estudiantes,
la app genera un plan de ejercicios personalizado y avisa cuándo toca
reevaluar. Hecha en **Flutter Web**, con autenticación en **Supabase**.

**Funcionalidades actuales**

- Inicio de sesión, registro con correo institucional y recuperación de
  contraseña, con tres roles: Administrador, Instructor y Estudiante.
- Evaluación de 10 ejercicios: press banca, dominadas, peso muerto,
  sentadilla, plancha lateral, plancha frontal, estocada, remo, jalón al
  pecho y curl de bíceps (0 a 3 cada uno, total sobre 30, con marca de
  dolor).
- Plan de ejercicios automático con los ejercicios de puntaje bajo.
- Progreso histórico por estudiante y alertas de reevaluación (5 semanas).
- Panel del administrador con métricas del centro.

**Estado:** la autenticación usa Supabase (o un modo demo local si no se
configura). Los estudiantes y evaluaciones todavía se guardan en el
navegador (`shared_preferences`); migrarlos a Supabase es el siguiente
paso.

**Documentación del proyecto de título:** las evidencias de cada fase
(grupales e individuales) están en la carpeta [`Fase 1/`](Fase%201/).

Inicio rápido (con Flutter ya instalado):

```
flutter pub get
flutter run -d chrome
```

---

## 1. Instalar Flutter en Windows (una sola vez)

Esto es más largo que instalar Node.js, tómate tu tiempo y ve paso a paso.

1. Ve a **https://docs.flutter.dev/get-started/install/windows** y descarga
   el archivo `.zip` del SDK de Flutter (botón "Download and install").
2. Crea la carpeta `C:\src` (si no existe) y extrae ahí el contenido del
   zip, de modo que quede `C:\src\flutter`. **No lo pongas dentro de
   `Archivos de programa` / `Program Files`**, porque los permisos de esa
   carpeta suelen dar problemas.
3. Agrega Flutter al PATH de Windows:
   - Escribe "variables de entorno" en el buscador de Windows y abre
     "Editar las variables de entorno del sistema".
   - Botón "Variables de entorno...".
   - En la lista de abajo ("Variables del sistema"), selecciona `Path` y
     dale "Editar".
   - "Nuevo" → escribe `C:\src\flutter\bin` → Aceptar en todas las
     ventanas.
4. **Cierra todas las ventanas de cmd que tengas abiertas y abre una
   nueva** (igual que con Node, el PATH nuevo solo se aplica a ventanas
   nuevas).
5. Verifica que funciona:
   ```
   flutter --version
   ```
   Debería mostrarte una versión (por ejemplo `Flutter 3.3x.x`).
6. Corre el diagnóstico de Flutter:
   ```
   flutter doctor
   ```
   Va a mostrar una lista con ✓ y ✗. **Solo nos importa que la línea de
   Chrome tenga ✓** (algo como `[✓] Chrome - develop for the web`). Las
   líneas de Android Studio o Visual Studio (C++) pueden quedar en ✗ o
   con advertencia: no las necesitamos porque esta app es solo para la
   web, así que ignóralas.
   - Si Chrome sale en ✗, instala Google Chrome normal
     (https://www.google.com/chrome/) y vuelve a correr `flutter doctor`.

Con eso, Flutter queda instalado. Este paso solo se hace una vez en tu
computador, aunque después sigamos trabajando en el proyecto.

---

## 2. Preparar el proyecto

1. Descomprime el archivo `caf_movimiento_flutter.zip` que te envié (por
   ejemplo en `Documentos`), igual que hiciste con el proyecto anterior.
2. Abre una ventana de **cmd** (símbolo del sistema) y entra a la carpeta
   del proyecto. Por ejemplo, si lo dejaste en Documentos:
   ```
   cd Documents\caf_movimiento_flutter
   ```
   Tip: usa `dir` para confirmar que ves los archivos `pubspec.yaml`,
   `lib` y `web` ahí mismo (igual que hacíamos con el proyecto anterior).
3. Descarga las dependencias del proyecto (equivalente al `npm install`
   de la versión anterior):
   ```
   flutter pub get
   ```
   Esto va a descargar `provider` y `shared_preferences`. Puede demorar
   uno o dos minutos la primera vez.

---

## 3. Ejecutar la app

Con el proyecto ya preparado, en la misma ventana de cmd:

```
flutter run -d chrome
```

Esto va a compilar la app y abrirla automáticamente en una ventana de
Chrome. La primera vez puede demorar 1-2 minutos en compilar; las
siguientes veces es más rápido.

Mientras esa ventana de cmd sigue abierta y corriendo, puedes:

- Presionar `r` en el cmd para "hot reload" (aplicar cambios de código sin
  cerrar la app).
- Presionar `q` para detener la app.

Para volver a abrirla otro día: repite este mismo comando (`flutter run
-d chrome`) desde la carpeta del proyecto.

### Generar una versión "para entregar" (build)

Si en algún momento necesitas un build listo para subir a un servidor o
mostrar sin depender de este cmd corriendo, usa:

```
flutter build web
```

Esto genera una carpeta `build\web` con archivos estáticos (HTML/JS/CSS)
que se pueden abrir con cualquier servidor web. Para la presentación del
proyecto, `flutter run -d chrome` (paso anterior) es suficiente y más
simple.

## 3.1 Inicio de sesión y roles

La app ahora parte en una pantalla de **inicio de sesión**. Según el rol
del usuario se muestran distintas secciones:

| Rol | Qué ve |
|---|---|
| Administrador | Panel general, vista Instructor y fichas de todos los estudiantes |
| Instructor | Vista Instructor y fichas de todos los estudiantes |
| Estudiante | Solo su propia ficha (se vincula por correo con el registro que crea el instructor) |

Quien se registra desde la app queda **siempre como estudiante** y solo
puede usar un correo institucional (`@duocuc.cl`, `@duoc.cl`,
`@profesor.duoc.cl`). Los roles de instructor y administrador los asigna
un administrador en la base de datos.

### Modo demo (sin configurar nada)

Si ejecutas `flutter run -d chrome` sin credenciales, la app arranca en
**modo demo** con cuentas de prueba (contraseña `caf12345`):

- `admin@duoc.cl` — Administrador
- `instructor@duoc.cl` — Instructor
- `javiera.munoz@duocuc.cl` — Estudiante

En el login aparecen como botones para entrar con un clic. Este modo es
solo para desarrollo: guarda las cuentas en el navegador, sin cifrar.

### Conectar Supabase (autenticación real)

1. Crea un proyecto gratuito en https://supabase.com.
2. En el panel: **SQL Editor** → pega el contenido de
   `supabase/migrations/0001_auth_profiles.sql` → **Run**. Esto crea la
   tabla `profiles` con los roles y sus reglas de seguridad (RLS).
3. En **Authentication → URL Configuration**, agrega en *Redirect URLs*
   la dirección donde corre la app (por ejemplo `http://localhost:5000`).
   Es a donde vuelven los enlaces de confirmación de correo y de
   recuperación de contraseña.
4. Copia `env.example.json` como `env.json` y completa los valores de
   **Project Settings → API Keys** (URL del proyecto y *publishable key*).
   `env.json` está en `.gitignore`: no lo subas al repositorio.
5. Ejecuta la app con esas credenciales (el puerto fijo es para que
   coincida con la Redirect URL):
   ```
   flutter run -d chrome --web-port 5000 --dart-define-from-file=env.json
   ```
6. Regístrate en la app con tu correo y luego, en el SQL Editor,
   conviértete en administrador:
   ```sql
   update public.profiles set role = 'admin' where email = 'tu.correo@duocuc.cl';
   ```
   De la misma forma se asigna `'instructor'` a los instructores.

> Los datos de estudiantes y evaluaciones todavía se guardan en el
> navegador (`shared_preferences`); solo la autenticación usa Supabase por
> ahora. Moverlos a Supabase es el siguiente paso.

### Pruebas

```
flutter test
```

---

## 4. Cómo ver y modificar el código

Igual que con el proyecto en Next.js: abre la carpeta completa
`caf_movimiento_flutter` en Visual Studio Code (`Archivo → Abrir
carpeta...`, no un archivo suelto).

Te recomiendo instalar la extensión **"Flutter"** en VS Code (busca
"Flutter" en la pestaña de extensiones — al instalarla se instala
también "Dart" automáticamente). Con eso VS Code te subraya errores en
rojo mientras escribes, cosa que yo no puedo hacer desde acá porque no
tengo Flutter instalado en este entorno.

Mapa rápido de dónde está cada cosa:

| Qué quieres cambiar | Archivo |
|---|---|
| Los 10 ejercicios evaluados (nombre, qué se observa, prescripción) | `lib/models/exercise.dart` |
| Estudiantes y evaluaciones de ejemplo (demo) | `lib/services/app_state.dart` (función `_seedDemoData`) |
| Reglas del plan de correctivos automático | `lib/services/recommendation.dart` |
| Colores / tema visual | `lib/theme.dart` |
| Pantalla del instructor (lista de estudiantes) | `lib/screens/instructor_screen.dart` |
| Formulario de evaluación (puntajes 0-3) | `lib/screens/evaluation_form_dialog.dart` |
| Pantalla del estudiante (ficha + gráfico) | `lib/screens/student_screen.dart` |
| Panel general / administrador | `lib/screens/admin_screen.dart` |
| Pantallas de login, registro y recuperación | `lib/screens/auth/` |
| Lógica de sesión (Supabase y modo demo) | `lib/services/auth/` |
| Qué secciones ve cada rol | `lib/screens/home_shell.dart` (`_sectionsFor`) |
| Tabla de perfiles/roles y seguridad en Supabase | `supabase/migrations/0001_auth_profiles.sql` |

Después de guardar un cambio en VS Code, con la app corriendo (`flutter
run -d chrome`), vuelve al cmd y presiona `r` para ver el cambio
reflejado sin reiniciar todo.

### Para "resetear" los datos de ejemplo

Como todo se guarda en el navegador (no hay base de datos como en la
versión Next.js), si quieres volver a ver los datos de ejemplo desde
cero, abre la app en una ventana de incógnito de Chrome, o borra los
datos del sitio (en Chrome: candadito junto a la dirección → "Configuración
del sitio" → "Borrar datos").

---

## 5. Relación con la propuesta técnica

- **Paso 1-2 (ficha digital y catálogo de ejercicios):**
  `lib/models/exercise.dart`,
  `lib/screens/evaluation_form_dialog.dart`.
- **Paso 3 (registro y seguimiento por estudiante):**
  `lib/screens/instructor_screen.dart`, `lib/screens/student_screen.dart`,
  `lib/widgets/progress_chart.dart` (gráfico de progreso histórico).
- **Paso 4 (motor de recomendación y alertas de reevaluación):**
  `lib/services/recommendation.dart` (plan automático según ejercicios
  débiles, próxima reevaluación a 5 semanas) y
  `lib/widgets/notification_banner.dart` (aviso cuando se acerca o vence
  la fecha).

**Fase 2** (módulo de cámara/IA para medir ángulos automáticamente) queda
pendiente para cuando la retomemos — con Flutter, esa parte normalmente
se aborda con paquetes de cámara y de visión (por ejemplo `camera` +
`google_mlkit` o TensorFlow Lite), que tienen sus propias limitaciones en
la versión web de Flutter. Lo vemos con calma cuando llegues a esa etapa.
