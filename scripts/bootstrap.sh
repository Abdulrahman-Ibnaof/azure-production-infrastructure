#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Creates the Terraform remote state backend on Azure
# Run ONCE before the first `terraform init`
# =============================================================================
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Config ────────────────────────────────────────────────────────────────────
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate$(openssl rand -hex 3)"
CONTAINER="tfstate"
LOCATION="${1:-eastus2}"

# ── Prereqs ───────────────────────────────────────────────────────────────────
command -v az   >/dev/null || error "Azure CLI not found. Install: https://docs.microsoft.com/cli/azure/install-azure-cli"
command -v jq   >/dev/null || error "jq not found. Install: brew install jq / apt install jq"

info "Checking Azure login..."
az account show &>/dev/null || az login

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
info "Subscription: $SUBSCRIPTION_ID | Tenant: $TENANT_ID"

# ── Create Resource Group ─────────────────────────────────────────────────────
info "Creating resource group: $RESOURCE_GROUP"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags ManagedBy=terraform Purpose=tfstate \
  --output none

# ── Create Storage Account ────────────────────────────────────────────────────
info "Creating storage account: $STORAGE_ACCOUNT"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_GRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false \
  --tags ManagedBy=terraform Purpose=tfstate \
  --output none

# ── Enable versioning and soft delete ────────────────────────────────────────
info "Enabling blob versioning and soft delete..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 90 \
  --output none

# ── Create Container ──────────────────────────────────────────────────────────
info "Creating blob container: $CONTAINER"
STORAGE_KEY=$(az storage account keys list \
  --resource-group "$RESOURCE_GROUP" \
  --account-name "$STORAGE_ACCOUNT" \
  --query '[0].value' -o tsv)

az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$STORAGE_KEY" \
  --output none

# ── Create Service Principal for CI/CD ───────────────────────────────────────
info "Creating service principal for GitHub Actions..."
SP_NAME="sp-terraform-${RANDOM}"
SP_JSON=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role Contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --json-auth)

# ── Output ────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo -e "${GREEN}✅  Bootstrap complete!${NC}"
echo "============================================================"
echo ""
echo "Backend config for main.tf:"
echo "  resource_group_name  = \"$RESOURCE_GROUP\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT\""
echo "  container_name       = \"$CONTAINER\""
echo ""
echo "GitHub Actions Secrets to add:"
echo "  AZURE_CLIENT_ID      = $(echo $SP_JSON | jq -r '.clientId')"
echo "  AZURE_CLIENT_SECRET  = $(echo $SP_JSON | jq -r '.clientSecret')"
echo "  AZURE_SUBSCRIPTION_ID= $SUBSCRIPTION_ID"
echo "  AZURE_TENANT_ID      = $TENANT_ID"
echo ""
echo "Next step:"
echo "  terraform init -backend-config=\"storage_account_name=$STORAGE_ACCOUNT\""
echo "============================================================"
