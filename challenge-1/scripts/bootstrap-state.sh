#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
APP_ID="ci36432"
LOCATION="eastus"
RG_NAME="rg-tfstate-${ENVIRONMENT}-${APP_ID}"
SA_NAME="sttfstate${ENVIRONMENT}${APP_ID}"
CONTAINER="tfstate"

if [[ -z "$ENVIRONMENT" ]]; then
  echo "Usage: $0 <environment>"
  echo "  e.g. $0 dev"
  echo "  e.g. $0 prod"
  exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "=== Bootstrapping Terraform State Storage ==="
echo "Environment:      ${ENVIRONMENT}"
echo "Subscription:     ${SUBSCRIPTION_ID}"
echo "Logged in as:     $(az account show --query user.name -o tsv)"
echo "Subscription name:$(az account show --query name -o tsv)"
echo "Tenant:           $(az account show --query tenantId -o tsv)"
echo "Resource Group:   ${RG_NAME}"
echo "Storage Account:  ${SA_NAME}"
echo "Container:        ${CONTAINER}"
echo "Location:         ${LOCATION}"
echo ""

echo "[1/3] Creating resource group..."
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  --subscription "$SUBSCRIPTION_ID" \
  --tags ApplicationId="$APP_ID" ManagedBy=bootstrap Environment="$ENVIRONMENT"

echo "[2/3] Creating storage account..."
az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --subscription "$SUBSCRIPTION_ID" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags ApplicationId="$APP_ID" ManagedBy=bootstrap Environment="$ENVIRONMENT"

echo "[3/3] Creating blob container..."
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA_NAME" \
  --subscription "$SUBSCRIPTION_ID"

echo ""
echo "=== State storage ready ==="
echo "Use: terraform init -backend-config=backends/${ENVIRONMENT}.backend.hcl"
