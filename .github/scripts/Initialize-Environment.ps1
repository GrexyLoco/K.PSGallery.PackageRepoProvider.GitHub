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

try {
    Write-Information "🚀 Initializing GitHub Provider Pipeline Environment"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    Install-PSResourceGetPreview
    
    Write-Information ""
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "✅ Environment initialization complete!"
    
} catch {
    Write-Error "Environment initialization failed: $_"
    throw
}
