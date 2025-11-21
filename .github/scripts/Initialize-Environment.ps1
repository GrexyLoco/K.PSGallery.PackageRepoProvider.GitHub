<#
.SYNOPSIS
    Initialize GitHub Actions environment for GitHub Provider pipeline
.DESCRIPTION
    Installs PSResourceGet preview and SecretManagement modules required for publishing
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-PSResourceGetPreview {
    [CmdletBinding()]
    param()
    
    Write-Information "🔧 Installing Microsoft.PowerShell.PSResourceGet 1.2.0-preview3..." -InformationAction Continue
    Install-Module -Name Microsoft.PowerShell.PSResourceGet `
        -RequiredVersion 1.2.0-preview3 `
        -Repository PSGallery `
        -Scope CurrentUser `
        -Force `
        -AllowPrerelease `
        -SkipPublisherCheck `
        -Verbose
    
    Import-Module -Name Microsoft.PowerShell.PSResourceGet -Force
    Write-Information "✅ PSResourceGet preview installed" -InformationAction Continue
}

function Install-SecretManagement {
    [CmdletBinding()]
    param()
    
    Write-Information "🔐 Installing SecretManagement modules..." -InformationAction Continue
    Install-PSResource -Name Microsoft.PowerShell.SecretManagement -Repository PSGallery -Scope CurrentUser -TrustRepository -Verbose
    Install-PSResource -Name SecretManagement.JustinGrote.CredMan -Repository PSGallery -Scope CurrentUser -TrustRepository -Verbose
    
    Write-Information "✅ SecretManagement installed" -InformationAction Continue
}

try {
    Write-Information "🚀 Initializing GitHub Provider Pipeline Environment" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    
    Install-PSResourceGetPreview
    Install-SecretManagement
    
    Write-Information "" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    Write-Information "✅ Environment initialization complete!" -InformationAction Continue
    
} catch {
    Write-Information "❌ Environment initialization failed: $_" -InformationAction Continue
    throw
}
