[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][ValidateSet('dev','prod')][string]$Environment,
  [ValidateSet('plan','apply','destroy','validate','fmt')][string]$Action='plan'
)
$ErrorActionPreference='Stop'
& node (Join-Path $PSScriptRoot 'deploy.mjs') $Environment $Action
if ($LASTEXITCODE -ne 0) { throw "Deployment command failed (exit $LASTEXITCODE)." }
