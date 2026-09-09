<#
.SYNOPSIS
    Initializes Azure Storage Account for Terraform remote state.
.DESCRIPTION
    Creates the Resource Group, Storage Account (TLS 1.2, private blob access), and Blob Container for remote state.
.EXAMPLE
    .\scripts\init-backend.ps1 -Location eastus
#>

[CmdletBinding()]
param (
    [string]$ResourceGroupName = "rg-terraform-state-prod",
    [string]$Location = "eastus",
    [string]$ContainerName = "tfstate"
)

$ErrorActionPreference = "Stop"

$RandomSuffix = -join ((97..122) + (48..57) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
$StorageAccountName = "sttfstate$RandomSuffix"

Write-Host "🚀 Initializing Azure Storage Backend for Terraform State..." -ForegroundColor Cyan
Write-Host "Resource Group  : $ResourceGroupName"
Write-Host "Storage Account : $StorageAccountName"
Write-Host "Container Name  : $ContainerName"
Write-Host "Location        : $Location"

# Verify Azure CLI login
try {
    az account show --output none
}
catch {
    Write-Host "Logging into Azure CLI..." -ForegroundColor Yellow
    az login
}

# Create Resource Group
Write-Host "`n📦 Creating resource group '$ResourceGroupName'..." -ForegroundColor Yellow
az group create `
    --name $ResourceGroupName `
    --location $Location `
    --tags Purpose="Terraform State" ManagedBy="Script" | Out-Null

# Create Storage Account
Write-Host "💾 Creating storage account '$StorageAccountName'..." -ForegroundColor Yellow
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --encryption-services blob `
    --https-only true `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access false | Out-Null

# Retrieve Storage Account Key
Write-Host "🔑 Retrieving storage account key..." -ForegroundColor Yellow
$AccountKey = az storage account keys list `
    --resource-group $ResourceGroupName `
    --account-name $StorageAccountName `
    --query '[0].value' -o tsv

# Create Blob Container
Write-Host "📂 Creating blob container '$ContainerName'..." -ForegroundColor Yellow
az storage container create `
    --name $ContainerName `
    --account-name $StorageAccountName `
    --account-key $AccountKey | Out-Null

Write-Host "`n✅ Terraform remote backend provisioned successfully!" -ForegroundColor Green
Write-Host "`n📋 Update your backend.tf files with the following configuration:" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "resource_group_name  = `"$ResourceGroupName`""
Write-Host "storage_account_name = `"$StorageAccountName`""
Write-Host "container_name       = `"$ContainerName`""
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
