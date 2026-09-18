<#!
Creates an Azure Storage backend using Entra authentication. Requires existing
resource deployment permissions and Storage Blob Data Contributor access.
!#>
[CmdletBinding()]
param(
    [string]$ResourceGroupName = 'rg-terraform-state',
    [string]$Location = 'eastus',
    [string]$ContainerName = 'tfstate',
    [string]$StorageAccountName = ('sttfstate' + [guid]::NewGuid().ToString('N').Substring(0,8))
)
$ErrorActionPreference = 'Stop'
function Invoke-Azure {
    param([string[]]$Arguments)
    & az @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Azure CLI failed (exit $LASTEXITCODE). Backend setup stopped." }
}
Invoke-Azure @('account','show','--output','none')
Invoke-Azure @('group','create','--name',$ResourceGroupName,'--location',$Location,'--tags','Purpose=TerraformState','ManagedBy=Script','--output','none')
Invoke-Azure @('storage','account','create','--name',$StorageAccountName,'--resource-group',$ResourceGroupName,'--location',$Location,'--sku','Standard_LRS','--https-only','true','--min-tls-version','TLS1_2','--allow-blob-public-access','false','--allow-shared-key-access','false','--output','none')
Invoke-Azure @('storage','account','blob-service-properties','update','--account-name',$StorageAccountName,'--resource-group',$ResourceGroupName,'--enable-versioning','true','--enable-delete-retention','true','--delete-retention-days','7','--output','none')
Invoke-Azure @('storage','container','create','--name',$ContainerName,'--account-name',$StorageAccountName,'--auth-mode','login','--public-access','off','--output','none')
Write-Output 'Backend created. Copy these values into the environment backend.hcl:'
Write-Output ('resource_group_name = "{0}"' -f $ResourceGroupName)
Write-Output ('storage_account_name = "{0}"' -f $StorageAccountName)
Write-Output ('container_name = "{0}"' -f $ContainerName)
Write-Output 'use_azuread_auth = true'
Write-Output 'Keep a separate state key per environment. No role assignments were created.'
