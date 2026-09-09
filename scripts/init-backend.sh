#!/bin/bash

# Script to initialize Terraform backend storage in Azure
# This creates the storage account for Terraform state files

set -e

# Variables - Customize these
RESOURCE_GROUP_NAME="rg-terraform-state-prod"
STORAGE_ACCOUNT_NAME="sttfstatepro$(openssl rand -hex 4)"  # Generates unique suffix
CONTAINER_NAME="tfstate"
LOCATION="eastus"

echo "🚀 Initializing Terraform Backend..."
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Location: $LOCATION"

# Login to Azure (if not already logged in)
az account show > /dev/null 2>&1 || az login

# Create resource group
echo "📦 Creating resource group..."
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --tags Purpose="Terraform State" ManagedBy="Script"

# Create storage account
echo "💾 Creating storage account..."
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv)

# Create blob container
echo "📂 Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --account-key $ACCOUNT_KEY

echo ""
echo "✅ Terraform backend initialized successfully!"
echo ""
echo "📋 Update your backend.tf with these values:"
echo "-------------------------------------------"
echo "resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "container_name       = \"$CONTAINER_NAME\""
echo "-------------------------------------------"
