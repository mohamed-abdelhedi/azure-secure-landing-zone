#!/usr/bin/env bash
# Creates a state backend. Requires Azure resource and Blob Data Contributor access.
set -euo pipefail
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-rg-terraform-state}
STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME:-sttfstate$(openssl rand -hex 4)}
CONTAINER_NAME=${CONTAINER_NAME:-tfstate}
LOCATION=${LOCATION:-eastus}

az account show --output none
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --tags Purpose=TerraformState ManagedBy=Script --output none
az storage account create --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --location "$LOCATION" --sku Standard_LRS --https-only true --min-tls-version TLS1_2 --allow-blob-public-access false --allow-shared-key-access false --output none
az storage account blob-service-properties update --account-name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --enable-versioning true --enable-delete-retention true --delete-retention-days 7 --output none
az storage container create --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --auth-mode login --public-access off --output none

printf 'Backend created. Copy these values into the environment backend.hcl:\n'
printf 'resource_group_name = "%s"\nstorage_account_name = "%s"\ncontainer_name = "%s"\nuse_azuread_auth = true\n' "$RESOURCE_GROUP_NAME" "$STORAGE_ACCOUNT_NAME" "$CONTAINER_NAME"
printf 'Keep a separate state key per environment. No role assignments were created.\n'
