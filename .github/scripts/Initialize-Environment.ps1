<#
.SYNOPSIS
    Initialize GitHub Actions environment for GitHub Provider pipeline
.DESCRIPTION
    Installs PSResourceGet preview required for publishing
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-PSResourceGetPreview {
    [CmdletBinding()]
    param()
    
    Write-Host "🔧 Installing Microsoft.PowerShell.PSResourceGet 1.2.0-preview3..." -ForegroundColor Cyan
    Install-Module -Name Microsoft.PowerShell.PSResourceGet `
        -RequiredVersion 1.2.0-preview3 `
        -Repository PSGallery `
        -Scope CurrentUser `
        -Force `
        -AllowPrerelease `
        -SkipPublisherCheck `
        -Verbose
    
    Import-Module -Name Microsoft.PowerShell.PSResourceGet -Force
    Write-Host "✅ PSResourceGet preview installed" -ForegroundColor Green
}

try {
    Write-Host "🚀 Initializing GitHub Provider Pipeline Environment" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    Install-PSResourceGetPreview
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "✅ Environment initialization complete!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Environment initialization failed: $_" -ForegroundColor Red
    throw
}
