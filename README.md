# Quinto y Parque · Backend (Firebase)

Repositorio: `salime45/quintoyparque-backend`  
Proyecto Firebase: `quintoyparque` · Nº `277470161375`

El backend inicial usa **Cloud Firestore y reglas de seguridad**. No hay Cloud Functions que desplegar todavía. Firebase Authentication con Google y Firestore ya están activados en la consola.

## GitHub Actions — configurado

[Workflow: Firestore - tests and deploy](https://github.com/salime45/quintoyparque-backend/actions/workflows/firestore.yml)

- **Push a `main` / pull requests:** ejecutan pruebas de reglas contra el emulador de Firestore.
- **Despliegue:** publica **solo las reglas de Firestore** del archivo `firestore.rules` después de pasar los tests.
- **Activación inicial:** el despliegue se ejecuta manualmente con `workflow_dispatch` una vez que esté configurada la identidad de Google Cloud.
- **Despliegue automático:** cuando la primera ejecución manual funcione, añadir la variable de repositorio `FIREBASE_BACKEND_DEPLOY_ENABLED` con valor `true` (Settings → Secrets and variables → Actions → Variables). Entonces cada push a `main` que afecte al workflow, reglas o pruebas hará el despliegue.
- **Autenticación:** Workload Identity Federation / OIDC, mediante tokens temporales. **No usa ni requiere secretos de cuentas de servicio**, `FIREBASE_TOKEN` ni archivos JSON con claves privadas.

## Primera autorización Google Cloud — paso único

Abre [Cloud Shell](https://shell.cloud.google.com/?project=quintoyparque) con una cuenta que sea propietaria o que pueda administrar IAM del proyecto, y ejecuta:

```bash
git clone https://github.com/salime45/quintoyparque-backend.git
cd quintoyparque-backend
bash scripts/setup-github-oidc.sh
```

El script necesita permisos para crear una cuenta de servicio, un pool/proveedor OIDC y asignar roles IAM. Si el proyecto pertenece a una organización con restricciones, estos permisos pueden requerir intervención del administrador.

El script hace lo siguiente:

1. Habilita las API necesarias para identidad federada y reglas.
2. Crea la cuenta `qyp-firestore-ci@quintoyparque.iam.gserviceaccount.com`.
3. Le otorga roles `roles/firebaserules.admin`, `roles/firebase.viewer` y `roles/serviceusage.serviceUsageConsumer`.
4. Crea el pool `github-qyp-backend` y proveedor `main` vinculados a la identidad OIDC de GitHub.
5. Restringe la autorización al repositorio concreto `salime45/quintoyparque-backend` (ID `1412330919`), propietario original (ID `10837217`) y rama `refs/heads/main`; el script no otorga permiso a otros repositorios ni ramas.
6. Permite a esa identidad utilizar la cuenta de servicio mediante `roles/iam.workloadIdentityUser`.

Espera a que propaguen los cambios IAM (puede tardar varios minutos). Después, en la pestaña [Actions](https://github.com/salime45/quintoyparque-backend/actions/workflows/firestore.yml), abre **Firestore - tests and deploy**, pulsa **Run workflow** y selecciona `main`. Revisa que los dos jobs terminen correctamente.

**Solo después de una ejecución correcta** conviene poner `FIREBASE_BACKEND_DEPLOY_ENABLED=true` en las variables de Actions para activar los despliegues automáticos.

## Reglas y esquema

- `places/{placeId}`: solo documentos `status: "published"` pueden consultarse públicamente; únicamente los administradores pueden crear, modificar o borrar.
- `places/{placeId}/reviews/{uid}`: un usuario identificado puede crear una reseña `pending` sobre un establecimiento existente y publicado. Una por usuario y sitio; puntuación 1–5; texto hasta 700 caracteres. El contenido pendiente solo es visible a administradores.
- `suggestions/{autoId}`: usuarios identificados pueden proponer nuevos establecimientos que se guardan privados y `pending`; solo los administradores pueden leerlos o editarlos.
- El rol administrador exige el custom claim `admin: true` asignado por Firebase Admin SDK desde una ubicación confiable; la web pública no puede asignarlo.

## Pruebas locales

Se necesita Node.js >= 22 y Java >= 21.

```bash
npm install
npm test
```

Esto inicia el emulador con proyecto ficticio `demo-quintoyparque` y ejecuta pruebas de acceso, validación, privacidad y moderación. **Las pruebas no acceden al Firestore real.**

## Precauciones

Las reglas publicadas por el workflow sustituyen las reglas actuales de Firestore en el proyecto. Mantén los cambios únicamente en este repositorio; no modifiques la versión de producción directamente desde Firebase Console.

El workflow **no despliega índices, datos de Firestore, Hosting ni funciones**. Cualquier configuración de frontend se mantiene independiente en `quintoyparque-frontend`. De momento las sugerencias y opiniones se moderarán fuera de la web; no existe un panel de administración.

Si la autenticación federada falla tras configurarla, revisa la configuración OIDC y el log de Actions antes de cambiar a credenciales de larga duración.
