# Paso a producción — CAF Movimiento

Esta guía explica cómo pasar del **modo demo** a una instalación real:
base de datos PostgreSQL en **Supabase** (nube) y la app web publicada en
**Netlify**. También explica cómo cada integrante desarrolla con una copia
local de la base, sin tocar los datos reales.

## 0. Los tres ambientes

| Ambiente | Para qué | Base de datos | Cómo se ejecuta |
|---|---|---|---|
| Demo | Probar pantallas rápido | Ninguna (navegador) | `flutter run -d chrome` |
| Desarrollo | Programar y probar cambios de la base | Supabase **local** (Docker) | `flutter run ... env.local.json` |
| Producción | Uso real del CAF | Supabase **en la nube** | Publicada en Netlify |

El modo demo **solo funciona al desarrollar**. Un build de producción sin
credenciales muestra "La aplicación no está configurada" en vez de entrar
con cuentas de prueba.

---

## 1. Desarrollo con Supabase local

Requisitos: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
abierto y [Node.js](https://nodejs.org) (para usar `npx`).

```
npx supabase start
flutter run -d chrome --web-port 5000 --dart-define-from-file=env.local.json
```

- `supabase start` levanta PostgreSQL, el login y la API en tu PC, aplica
  las migraciones de `supabase/migrations/` y carga los datos de ejemplo de
  `supabase/seed.sql`. La primera vez descarga varias imágenes y puede
  demorar unos minutos.
- `env.local.json` ya trae la URL y la key local (son las mismas en todos los
  computadores, no son secretas).
- **Supabase Studio** (ver y editar tablas): http://127.0.0.1:54323
- **Correos de prueba** (confirmación, recuperar contraseña): http://127.0.0.1:54324
- Para hacerte administrador en local: en Studio → SQL Editor:
  ```sql
  update public.profiles set role = 'admin' where email = 'tu.correo@duocuc.cl';
  ```
- `npx supabase db reset` borra la base local y la vuelve a crear desde
  las migraciones (útil para partir de cero).
- `npx supabase stop` la apaga.

### Cambiar la base de datos

Nunca modifiques una migración que ya se aplicó en producción. Para
cualquier cambio crea una nueva:

```
npx supabase migration new descripcion_del_cambio
```

Escribe el SQL en el archivo creado en `supabase/migrations/`, pruébalo con
`npx supabase db reset` y, cuando funcione, súbelo a producción (paso 3).

---

## 2. Crear el proyecto en Supabase (una sola vez)

1. Entra a https://supabase.com y crea una cuenta (puede ser con GitHub).
   Idealmente crea una **organización** del equipo y agrega a los
   integrantes, para que el proyecto no dependa de una sola persona.
2. **New project**:
   - Nombre: `caf-movimiento`
   - **Database password**: genera una segura y **guárdala** en un gestor
     de contraseñas. Se pide al subir migraciones.
   - Región: **South America (São Paulo)**, la más cercana a Chile.
3. Espera a que el proyecto termine de crearse (1-2 minutos).

## 3. Subir las tablas (migraciones)

Desde la carpeta del proyecto:

```
npx supabase login
npx supabase link --project-ref TU_PROJECT_REF
npx supabase db push
```

- `TU_PROJECT_REF` es el código que aparece en la URL del panel:
  `supabase.com/dashboard/project/TU_PROJECT_REF`.
- `db push` aplica todas las migraciones (`0001` a `0004`) y recuerda cuáles ya se
  aplicaron, así que después solo sube las nuevas.
- Los datos de ejemplo (`seed.sql`) **no** se suben a producción.

## 4. Configurar el inicio de sesión

En el panel de Supabase → **Authentication**:

1. **URL Configuration**
   - *Site URL*: la dirección de Netlify (paso 6), por ejemplo
     `https://caf-movimiento.netlify.app`.
   - *Redirect URLs*: esa misma dirección y `http://localhost:5000`.
2. **Sign In / Providers → Email**
   - *Confirm email*: **activado**.
   - *Minimum password length*: **8**, con letras y números (es lo mismo
     que exige la app).
3. **Emails → SMTP Settings** — **importante**: el servicio de correo
   incluido en Supabase solo envía a los integrantes del equipo del
   proyecto y tiene un límite muy bajo por hora. Para que los estudiantes
   reciban el correo de confirmación hay que configurar un SMTP propio
   (por ejemplo Resend, Brevo o el correo institucional, si TI lo permite).
   Sin esto, los estudiantes no podrán confirmar su cuenta.

## 5. Credenciales de producción para la app

En el panel: **Project Settings → API Keys**. Copia `env.example.json`
como `env.json` y completa:

```json
{
  "SUPABASE_URL": "https://TU_PROJECT_REF.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

- La *publishable key* es pública por diseño (va dentro de la app); la
  seguridad la dan las reglas RLS de la base de datos.
- **Nunca** pongas la *secret key* ni la contraseña de la base en la app ni
  en el repositorio. `env.json` ya está en `.gitignore`.

## 6. Publicar en Netlify

### Opción A — conectada a GitHub (recomendada)

Cada `push` a `main` publica una versión nueva automáticamente.

1. Entra a https://app.netlify.com → **Add new project → Import an
   existing project** → GitHub → elige el repositorio.
2. Netlify lee `netlify.toml`, así que no hay que configurar el comando de
   build.
3. En **Site configuration → Environment variables** agrega
   `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` con los valores del paso 5.
4. **Deploy**. El primer build demora unos minutos porque descarga Flutter.
5. En **Domain management** puedes cambiar el nombre, por ejemplo
   `caf-movimiento.netlify.app`. Usa esa dirección en el paso 4.

### Opción B — subirla a mano

```
flutter build web --release --dart-define-from-file=env.json
npx netlify-cli deploy --prod
```

(o arrastra la carpeta `build/web` a https://app.netlify.com/drop).

## 7. Primer administrador e instructores

Solo el **primer** administrador se crea por SQL; el resto se hace desde
la app.

1. Abre la app publicada y regístrate con tu correo institucional.
2. Confirma el correo.
3. En Supabase → **SQL Editor**:
   ```sql
   update public.profiles set role = 'admin' where email = 'tu.correo@duocuc.cl';
   ```
4. Cierra sesión y vuelve a entrar: verás la sección **Usuarios**.
5. Pide a los instructores que se registren en la app. Luego, en
   **Usuarios**, cambia su rol de *Estudiante* a *Instructor* (o
   *Administrador*). Lo verán la próxima vez que inicien sesión.

Reglas: solo un administrador cambia roles, nadie cambia su propio rol
desde la app y la base de datos impide quedarse sin administradores.

---

## 8. Ver la base de datos con DBeaver

[DBeaver Community](https://dbeaver.io/download/) (gratis) sirve para ver
tablas, filtrar datos y ejecutar consultas con una interfaz más cómoda que
el panel web. En DBeaver: **Nueva conexión → PostgreSQL** y completa:

| Campo | Supabase local | Supabase en la nube |
|---|---|---|
| Host | `127.0.0.1` | El del *Session pooler* (ver abajo), p. ej. `aws-0-sa-east-1.pooler.supabase.com` |
| Puerto | `54322` | `5432` |
| Base de datos | `postgres` | `postgres` |
| Usuario | `postgres` | `postgres.TU_PROJECT_REF` |
| Contraseña | `postgres` | La *Database password* del paso 2 |
| SSL | No | **require** (pestaña SSL) |

- **Local:** requiere que `npx supabase start` esté corriendo.
- **Nube:** en el panel de Supabase, botón **Connect** (arriba) → pestaña
  *Connection String* → **Session pooler**. Ahí aparecen el host y el
  usuario exactos. No uses *Direct connection*: solo funciona con IPv6 y
  en la mayoría de las redes de Chile falla.
- Las tablas de la app están en el esquema **public**: `profiles`,
  `students`, `evaluations`, `evaluation_scores`,
  `evaluation_plan_items` y `exercises`.
- Las primeras veces DBeaver ofrece descargar el *driver* de PostgreSQL:
  acéptalo.

**Cuidados al conectarse a producción:**

- El usuario `postgres` es administrador de la base: **no le aplican las
  reglas RLS** y puede ver y borrar todo. En la conexión de la nube marca
  *Connection type: Production* (DBeaver pide confirmar cada cambio) o
  *Read-only connection* si solo vas a mirar.
- No cambies la **estructura** de las tablas (columnas, tablas nuevas,
  reglas) desde DBeaver: hazlo con una migración (sección 1), si no la
  base local y la de producción quedan distintas.
- Editar **datos** sí está bien. Por ejemplo, el primer administrador se
  puede crear desde DBeaver con el mismo `update` del paso 7. Las reglas
  de la base siguen funcionando: no se puede quitar al último
  administrador y borrar un estudiante borra también sus evaluaciones.

---

## Lista de verificación antes de usarla con estudiantes

- [ ] Migraciones aplicadas (`npx supabase migration list` muestra 0001 a 0004 en *Remote*).
- [ ] Site URL y Redirect URLs apuntan a la dirección de Netlify.
- [ ] *Confirm email* activado y SMTP propio configurado.
- [ ] Variables de entorno cargadas en Netlify; la app publicada **no**
      muestra "MODO DEMO" en el login.
- [ ] Registro de prueba con un correo institucional: llega el correo,
      se confirma y el estudiante aparece en la lista del instructor.
- [ ] Al menos un administrador y los instructores con su rol asignado.
- [ ] Contraseña de la base guardada en un lugar seguro y más de un
      integrante con acceso al proyecto de Supabase y a Netlify.
