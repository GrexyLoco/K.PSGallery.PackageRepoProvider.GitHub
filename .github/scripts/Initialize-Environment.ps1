<#
.SYNOPSIS
    Initialize GitHub Actions environment for GitHub Provider pipeline
.DESCRIPTION
    Installs PSResourceGet preview, SecretManagement, and PSScriptAnalyzer modules required for the pipeline
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function Install-PSResourceGetPreview {
    [CmdletBinding()]
    param()
    
    Write-Information "🔧 Installing Microsoft.PowerShell.PSResourceGet 1.2.0-preview3..."
    Install-Module -Name Microsoft.PowerShell.PSResourceGet `
        -RequiredVersion 1.2.0-preview3 `
        -Repository PSGallery `
        -Scope CurrentUser `
        -Force `
        -AllowPrerelease `
        -SkipPublisherCheck `
        -Verbose
    
    Import-Module -Name Microsoft.PowerShell.PSResourceGet -Force
    Write-Information "✅ PSResourceGet preview installed"
}

function Install-SecretManagement {
    [CmdletBinding()]
    param()
    
    Write-Information "🔐 Installing SecretManagement modules..."
    Install-PSResource -Name Microsoft.PowerShell.SecretManagement -Repository PSGallery -Scope CurrentUser -TrustRepository -Verbose
    Install-PSResource -Name SecretManagement.JustinGrote.CredMan -Repository PSGallery -Scope CurrentUser -TrustRepository -Verbose
    
    Write-Information "✅ SecretManagement installed"
}

function Install-PSScriptAnalyzer {
    [CmdletBinding()]
    param()
    
    Write-Information "🔍 Installing PSScriptAnalyzer..."
    Install-PSResource -Name PSScriptAnalyzer -Repository PSGallery -Scope CurrentUser -TrustRepository -Verbose
    
    Write-Information "✅ PSScriptAnalyzer installed"
}

try {
    Write-Information "🚀 Initializing GitHub Provider Pipeline Environment"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    Install-PSResourceGetPreview
    Install-SecretManagement
    Install-PSScriptAnalyzer
    
    Write-Information ""
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "✅ Environment initialization complete!"
    
} catch {
    Write-Error "Environment initialization failed: $_"
    throw
}
