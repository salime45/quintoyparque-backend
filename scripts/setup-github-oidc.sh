#!/usr/bin/env bash
# Ejecutar una sola vez en Google Cloud Shell, con permisos IAM de administracion
# en el proyecto Firebase quintoyparque.
set -euo pipefail

PROJECT_ID="quintoyparque"
PROJECT_NUMBER="277470161375"
POOL_ID="github-qyp-backend"
PROVIDER_ID="main"
SERVICE_ACCOUNT_ID="qyp-firestore-ci"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
GITHUB_REPO="salime45/quintoyparque-backend"
GITHUB_REPO_ID="1412330919"
GITHUB_OWNER_ID="10837217"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Instala Google Cloud CLI o abre Google Cloud Shell." >&2
  exit 1
fi

echo "Proyecto: ${PROJECT_ID}"
gcloud config set project "$PROJECT_ID" >/dev/null
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  firebaserules.googleapis.com \
  --project="$PROJECT_ID"

if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SERVICE_ACCOUNT_ID" \
    --project="$PROJECT_ID" --display-name="GitHub Quinto y Parque - reglas Firestore"
fi

for role in roles/firebaserules.admin roles/firebase.viewer roles/serviceusage.serviceUsageConsumer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="$role" --quiet >/dev/null
done

if ! gcloud iam workload-identity-pools describe "$POOL_ID" \
  --project="$PROJECT_ID" --location=global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL_ID" \
    --project="$PROJECT_ID" --location=global \
    --display-name="GitHub Quinto y Parque backend"
fi

# El proveedor solo aceptara tokens del repositorio GitHub concreto y de main.
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
  --project="$PROJECT_ID" --location=global \
  --workload-identity-pool="$POOL_ID" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
    --project="$PROJECT_ID" --location=global \
    --workload-identity-pool="$POOL_ID" \
    --display-name="Backend main (GitHub)" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository_id=assertion.repository_id" \
    --attribute-condition="assertion.repository_id=='${GITHUB_REPO_ID}' && assertion.repository_owner_id=='${GITHUB_OWNER_ID}' && assertion.repository=='${GITHUB_REPO}' && assertion.ref=='refs/heads/main'"
else
  echo "AVISO: el proveedor ya existe. Comprueba su condicion antes de continuar."
  gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
    --project="$PROJECT_ID" --location=global \
    --workload-identity-pool="$POOL_ID" \
    --format="yaml(attributeCondition,attributeMapping)"
fi

gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository_id/${GITHUB_REPO_ID}" \
  --quiet >/dev/null

echo ""
echo "OIDC configurado para ${GITHUB_REPO} (main)."
echo "Sin claves privadas: el workflow de GitHub puede solicitar tokens temporales."
echo "Espera unos minutos a que IAM propague y lanza el workflow manualmente:"
echo "https://github.com/${GITHUB_REPO}/actions/workflows/firestore.yml"
echo "Cuando pase correctamente, crea la variable en GitHub Actions:"
echo "FIREBASE_BACKEND_DEPLOY_ENABLED=true"
