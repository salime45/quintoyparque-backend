# Quinto y Parque — backend

Proyecto Firebase: `quintoyparque` (número `277470161375`).

Este repositorio contiene las reglas y los índices de Cloud Firestore. Firestore y Authentication (Google) se han activado en Firebase Console; todavía falta publicar estas reglas.

## Despliegue
Desde la raíz de este repositorio, usando una sesión de `firebase login` autorizada:

```bash
firebase deploy --project quintoyparque --only firestore:rules
```

Después, desde `quintoyparque-frontend`, se puede desplegar el sitio con `firebase deploy --project quintoyparque --only hosting`.

El script `deploy.ps1` en el repositorio frontend realiza ambos despliegues en ese orden.

## Modelo actual
- `places/{id}`: locales publicados con `status: "published"` y posición `lat`/`lng`. Los administradores pueden escribirlos; los usuarios pueden consultar únicamente los publicados.
- `places/{id}/reviews/{uid}`: reseñas pendientes, con valor 1–5 y texto de hasta 700 caracteres. Cada usuario solo puede crear una reseña pendiente por lugar; un administrador puede aprobarla.
- `suggestions/{id}`: sugerencias privadas aportadas por usuarios autenticados. Quedan pendientes de moderación.

Para moderación se usa el custom claim `admin: true` asignado desde un entorno de confianza mediante Firebase Admin SDK, nunca desde la web pública.

Las reglas deben revisarse y probarse con el emulador antes de abrir aportaciones a gran escala. De momento no existe un panel de moderación, y la interfaz de reseñas aún no está implementada. No subir credenciales o claves privadas.
