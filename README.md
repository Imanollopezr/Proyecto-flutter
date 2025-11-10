# PetLove API — Despliegue en Render

Esta guía explica cómo desplegar SOLO el backend (.NET 8) en Render usando el `render.yaml` y el `Dockerfile` incluidos.

## Pasos para Render

1. Conecta el repositorio
   - En Render, entra a `New > Blueprint`.
   - Selecciona tu repo `Imanollopezr/Proyecto-flutter` y autoriza el acceso.
   - Render detectará el `render.yaml` en la raíz y propondrá crear el servicio `petlove-api` con `runtime: docker`.

2. Revisa la configuración del servicio
   - Tipo: `web`.
   - Runtime: `docker` (usa el `Dockerfile` en `api-backend/api-backend/PetLove.API/`).
   - Región y plan: escoge los que prefieras.

3. Añade variables de entorno (Secrets)
   - Base de datos (PostgreSQL):
     - `ConnectionStrings__DefaultConnection` → cadena de conexión PostgreSQL.
       - En Render, usa el valor de `DATABASE_URL` (cópialo tal cual) o el formato: `Host=<host>;Port=5432;Database=<db>;Username=<user>;Password=<pass>;SSL Mode=Require;Trust Server Certificate=true`.
   - JWT:
     - `Jwt__Key` → clave secreta para firmar tokens (string suficientemente largo).
     - `Jwt__Issuer` → por ejemplo `PetLove.API`.
     - `Jwt__Audience` → por ejemplo `PetLove.Client`.
     - `Jwt__ExpiryInHours` → horas de expiración (por ejemplo `2`).
     - `Jwt__RefreshTokenExpiryInDays` → días de expiración del refresh (por ejemplo `7`).
   - SendGrid:
     - `SendGrid__ApiKey` → tu API key de SendGrid (no commitear en código).
     - `SendGrid__FromEmail` → correo remitente (opcional).
     - `SendGrid__FromName` → nombre remitente (opcional).
     - `SendGrid__Templates__Welcome` → ID de plantilla (opcional).
     - `SendGrid__Templates__VerificationCode` → ID de plantilla (opcional).
     - `SendGrid__Templates__PasswordReset` → ID de plantilla (opcional).
   - Frontend (para enlaces en emails):
     - `Frontend__BaseUrl` → URL pública del frontend (opcional).

4. Crea el servicio
   - Confirma el Blueprint y Render creará el servicio.
   - Render descargará el repo, buildará la imagen Docker y levantará la API.

5. Verifica el despliegue
   - Abre los Logs en Render para confirmar el arranque.
   - La API aplica automáticamente las migraciones de EF Core al iniciar.
   - Prueba el endpoint raíz o Swagger (si está habilitado) en la URL pública del servicio.

6. Seguridad y buenas prácticas
   - No subas secretos en el código (usa variables de entorno de Render).
   - Si algún secreto se publicó por error, revócalo y crea uno nuevo.

## Estructura relevante

- `render.yaml` (raíz): define el servicio `petlove-api` con `runtime: docker`.
- `api-backend/api-backend/PetLove.API/Dockerfile`: multi-stage para .NET 8.
- `api-backend/api-backend/PetLove.API/appsettings.json`: valores por defecto; se sobreescriben con variables de entorno.

## Nota

Este repo también contiene la app Flutter, pero Render desplegará únicamente el backend apuntando al subdirectorio del API mediante el `Dockerfile`.