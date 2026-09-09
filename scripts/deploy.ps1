<#
.SYNOPSIS
    Terraform deployment helper script for PowerShell.
.DESCRIPTION
    Wraps terraform initialization, validation, planning, and deployment across environments.
.EXAMPLE
    .\scripts\deploy.ps1 -Environment dev -Action plan
.EXAMPLE
    .\scripts\deploy.ps1 -Environment prod -Action apply
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("dev", "prod")]
    [string]$Environment,

    [Parameter(Position = 1)]
    [ValidateSet("plan", "apply", "destroy", "validate", "fmt")]
    [string]$Action = "plan"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$EnvDir = Join-Path $RepoRoot "environments\$Environment"

if (-not (Test-Path $EnvDir)) {
    Write-Error "❌ Environment '$Environment' not found at: $EnvDir"
    exit 1
}

Push-Location $EnvDir
try {
    Write-Host "🚀 Terraform $Action for environment: $Environment" -ForegroundColor Cyan
    Write-Host "📁 Directory: $EnvDir" -ForegroundColor DarkGray

    Write-Host "`n📦 Checking Terraform formatting..." -ForegroundColor Yellow
    terraform fmt -check -recursive

    Write-Host "`n📦 Initializing Terraform..." -ForegroundColor Yellow
    terraform init

    Write-Host "`n✅ Validating configuration..." -ForegroundColor Yellow
    terraform validate

    switch ($Action) {
        "fmt" {
            Write-Host "🎨 Formatting code..." -ForegroundColor Cyan
            terraform fmt -recursive
        }
        "validate" {
            Write-Host "✅ Validation successful." -ForegroundColor Green
        }
        "plan" {
            Write-Host "`n📋 Creating Terraform plan..." -ForegroundColor Cyan
            terraform plan -out=tfplan
        }
        "apply" {
            if ($Environment -eq "prod") {
                Write-Host "`n⚠️ WARNING: You are deploying to PRODUCTION!" -ForegroundColor Red
                $Confirm = Read-Host "Type 'yes' to proceed with production deployment"
                if ($Confirm -ne "yes") {
                    Write-Host "Deployment aborted by user." -ForegroundColor Yellow
                    return
                }
            }
            Write-Host "`n🔨 Applying changes..." -ForegroundColor Cyan
            terraform apply -auto-approve tfplan
        }
        "destroy" {
            Write-Host "`n💣 DANGER: This will DESTROY all resources in $Environment!" -ForegroundColor Red
            $Confirm = Read-Host "Type 'destroy-$Environment' to confirm"
            if ($Confirm -ne "destroy-$Environment") {
                Write-Host "Destruction aborted by user." -ForegroundColor Yellow
                return
            }
            terraform destroy
        }
    }
    Write-Host "`n✨ Action '$Action' completed successfully!" -ForegroundColor Green
}
finally {
    Pop-Location
}
