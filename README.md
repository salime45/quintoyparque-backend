# Quinto y Parque — backend

Firebase project: `quintoyparque` (277470161375).

Este repositorio define las reglas de Cloud Firestore. Configura Firestore en Firebase Console y despliega desde esta carpeta con `firebase deploy --project quintoyparque --only firestore`.

## Modelo
- `places/{id}`: locales con `status: "published"`; solo los administradores pueden publicar o cambiar datos.
- `places/{id}/reviews/{uid}`: opiniones con puntuación de 1 a 5 y estado `pending`. Una reseña pendiente por usuario y local. Los moderadores pueden publicarlas.
- `suggestions/{id}`: propuesta privada enviada por un usuario identificado, siempre `pending`.

La administración requiere el custom claim `admin: true`, asignado desde un entorno de confianza (nunca desde frontend).

## Pendiente
No se ha configurado ni desplegado Firebase; faltan habilitar Firestore y Auth en consola. Aún no hay herramientas de moderación, y las opiniones no se muestran en el frontend. No subir cuentas de servicio ni claves privadas a Git.
